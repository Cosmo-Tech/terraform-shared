#!/bin/sh

AZURE_STORAGE_ACCOUNT=""
AZURE_STORAGE_KEY=""
TARGET=""

usage() {
    echo "Usage: $0 -n <shared | namespace_name> -s <storage_account_name> -k <storage_account_key>"
    exit 1
}

while [ $# -gt 0 ]; do
    case "$1" in
        -n|-namespace|--namespace)
            TARGET="$2"; shift 2 ;;
        -s|-sa-name|--sa-name)
            AZURE_STORAGE_ACCOUNT="$2"; shift 2 ;;
        -k|-sa-key|--sa-key)
            AZURE_STORAGE_KEY="$2"; shift 2 ;;
        *) usage ;;
    esac
done

if [ -z "$AZURE_STORAGE_ACCOUNT" ] || [ -z "$AZURE_STORAGE_KEY" ] || [ -z "$TARGET" ]; then
    usage
fi

export AZURE_STORAGE_ACCOUNT
export AZURE_STORAGE_KEY

# Vérification des prérequis
for cmd in kubectl base64 az yq; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "error: required command not found: $cmd"
        exit 1
    fi
done

CLUSTER="$(kubectl config current-context)"
MAIN_NAME="migrate-psql-$CLUSTER"
DIR_DUMP="$MAIN_NAME"
CONTAINER_NAME="$MAIN_NAME"

mkdir -p "$DIR_DUMP"

# Vérification de l'existence du container Azure
if [ "$(az storage container exists --account-name "$AZURE_STORAGE_ACCOUNT" --account-key "$AZURE_STORAGE_KEY" --name "$CONTAINER_NAME" --query "exists" -o tsv | tr -d '\r\n ')" != "true" ]; then
    echo "ERROR: Remote Azure Storage Container '$CONTAINER_NAME' does not exist."
    exit 1
fi

all_cluster_ns="$(kubectl get ns -o jsonpath='{.items[*].metadata.name}')"
all_ns=""

if [ "$TARGET" = "shared" ]; then
    for ns in $all_cluster_ns; do
        if [ "$ns" = "keycloak" ] || [ "$ns" = "harbor" ] || [ "$ns" = "superset" ]; then
            all_ns="$all_ns $ns"
        fi
    done
else
    for ns in $all_cluster_ns; do
        if [ "$ns" = "$TARGET" ]; then
            all_ns="$ns"
            break
        fi
    done
fi

[ -z "$all_ns" ] && { echo "ERROR: Namespace '$TARGET' not found on cluster"; exit 1; }

scale_apps() {
    local ns=$1
    local replicas=$2
    for dep in $(kubectl get deployments -n "$ns" -o jsonpath='{.items[*].metadata.name}' 2>/dev/null); do
        if ! echo "$dep" | grep -q "sql"; then
            kubectl scale deployment -n "$ns" "$dep" --replicas="$replicas" >/dev/null 2>&1
        fi
    done
    for sts in $(kubectl get statefulsets -n "$ns" -o jsonpath='{.items[*].metadata.name}' 2>/dev/null); do
        if ! echo "$sts" | grep -q "sql"; then
            kubectl scale statefulset -n "$ns" "$sts" --replicas="$replicas" >/dev/null 2>&1
        fi
    done
}

restore_psql() {
    local ns=$1
    local pod=$2
    local super_user=$3
    local super_pwd=$4
    local db=$5
    local blob_name=$6
    local cluster_name=$7
    local local_tmp_dump="$DIR_DUMP/_tmp_restore.sql"

    # --- 1. Détection de l'utilisateur applicatif ---
    local app_user=""
    if echo "$ns" | grep -q "tenant"; then
        app_user="postgres"
    elif echo "$ns" | grep -q "keycloak"; then
        app_user="postgres"
    elif echo "$ns" | grep -q "harbor"; then
        app_user="postgres"
    elif echo "$ns" | grep -q "superset"; then
        app_user="bn_superset"
    else
        # Fallback dynamique si le namespace est inconnu (utilise le standard CNPG)
        app_user=$(kubectl get secret -n "$ns" "${cluster_name}-app" -o jsonpath='{.data.username}' 2>/dev/null | base64 -d)
    fi

    echo "  -> Downloading $blob_name from Azure Storage..."
    az storage blob download --account-name "$AZURE_STORAGE_ACCOUNT" --account-key "$AZURE_STORAGE_KEY" --container-name "$CONTAINER_NAME" --name "$blob_name" --file "$local_tmp_dump" --output none

    echo "  -> Scaling down application workloads in $ns..."
    scale_apps "$ns" 0

    # --- 2. Création de la base de données ---
    db_exists=$(kubectl exec -n "$ns" "$pod" -c postgres -- env PGPASSWORD="$super_pwd" psql -h 127.0.0.1 -U "$super_user" -d postgres -t -A -c "SELECT 1 FROM pg_database WHERE datname='$db';" 2>/dev/null)
    
    if [ "$db_exists" != "1" ] && [ "$db" != "postgres" ]; then
        echo "     Creating target database '$db'..."
        if [ -n "$app_user" ] && [ "$app_user" != "$super_user" ]; then
            kubectl exec -n "$ns" "$pod" -c postgres -- env PGPASSWORD="$super_pwd" psql -h 127.0.0.1 -U "$super_user" -d postgres -c "CREATE DATABASE \"$db\" OWNER \"$app_user\";" >/dev/null 2>&1
        else
            kubectl exec -n "$ns" "$pod" -c postgres -- env PGPASSWORD="$super_pwd" psql -h 127.0.0.1 -U "$super_user" -d postgres -c "CREATE DATABASE \"$db\";" >/dev/null 2>&1
        fi
    fi

    # --- 3. Importation des données ---
    echo "  -> Importing dump into '$db'..."
    kubectl exec -i -n "$ns" "$pod" -c postgres -- env PGPASSWORD="$super_pwd" psql -h 127.0.0.1 -U "$super_user" -d "$db" < "$local_tmp_dump" >/dev/null 2>&1

    # --- 4. Application des droits (uniquement si l'utilisateur applicatif est différent du super_user) ---
    if [ -n "$app_user" ] && [ "$app_user" != "$super_user" ]; then
        echo "     Fixing table permissions for application user '$app_user'..."
        kubectl exec -i -n "$ns" "$pod" -c postgres -- env PGPASSWORD="$super_pwd" psql -h 127.0.0.1 -U "$super_user" -d "$db" >/dev/null 2>&1 <<EOF
GRANT ALL PRIVILEGES ON DATABASE "$db" TO "$app_user";
ALTER SCHEMA public OWNER TO "$app_user";
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO "$app_user";
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO "$app_user";
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO "$app_user";
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO "$app_user";
EOF
    fi

    echo "  -> Scaling back up application workloads in $ns..."
    scale_apps "$ns" 1

    rm -f "$local_tmp_dump"
}

# --- BOUCLE PRINCIPALE ---
for ns in $all_ns; do
    echo -e "\nProcessing namespace '$ns'..."

    # Recherche dynamique du cluster CNPG
    CLUSTER_NAME=$(kubectl get clusters.postgresql.cnpg.io -n "$ns" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    [ -z "$CLUSTER_NAME" ] && { echo "WARNING: No CNPG cluster found in $ns"; continue; }

    # Recherche exclusive du pod primaire de ce cluster CNPG
    selected_pod=$(kubectl get pod -n "$ns" -l "cnpg.io/cluster=$CLUSTER_NAME,role=primary" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    [ -z "$selected_pod" ] && { echo "WARNING: No primary CNPG pod found in $ns"; continue; }

    # Récupération des identifiants SuperAdmin CNPG
    cnpg_sec="${CLUSTER_NAME}-superuser"
    psql_pwd=$(kubectl get secret -n "$ns" "$cnpg_sec" -o jsonpath='{.data.password}' 2>/dev/null | base64 -d)
    psql_user=$(kubectl get secret -n "$ns" "$cnpg_sec" -o jsonpath='{.data.username}' 2>/dev/null | base64 -d)
    [ -z "$psql_pwd" ] && { echo "WARNING: CNPG superuser secret ($cnpg_sec) not found in $ns"; continue; }

    echo "Fetching dump files from Azure Storage..."
    blobs=$(az storage blob list --account-name "$AZURE_STORAGE_ACCOUNT" --account-key "$AZURE_STORAGE_KEY" --container-name "$CONTAINER_NAME" --prefix "$ns/" --query "[].name" -o tsv)

    [ -z "$blobs" ] && { echo "WARNING: No dump files found for $ns"; continue; }

    for blob_path in $blobs; do
        db=$(basename "$blob_path" .sql)
        echo " -> Starting restore for database '$db' into $selected_pod"
        restore_psql "$ns" "$selected_pod" "$psql_user" "$psql_pwd" "$db" "$blob_path" "$CLUSTER_NAME"
    done
done

echo -e "\nRestore process completed!"
exit 0