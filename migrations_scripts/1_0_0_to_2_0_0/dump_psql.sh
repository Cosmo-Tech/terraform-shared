#!/bin/sh

TARGET_NAMESPACE="all"
AZURE_STORAGE_ACCOUNT=""
AZURE_STORAGE_KEY=""

usage() {
    echo "Usage: $0 -s <storage_account_name> -k <storage_account_key> [-n <namespace>]"
    exit 1
}

while [ $# -gt 0 ]; do
    case "$1" in
        -s|-sa-name|--sa-name)
            AZURE_STORAGE_ACCOUNT="$2"; shift 2 ;;
        -k|-sa-key|--sa-key)
            AZURE_STORAGE_KEY="$2"; shift 2 ;;
        -n|-namespace|--namespace)
            TARGET_NAMESPACE="$2"; shift 2 ;;
        *) usage ;;
    esac
done

if [ -z "$AZURE_STORAGE_ACCOUNT" ] || [ -z "$AZURE_STORAGE_KEY" ]; then
    usage
fi

export AZURE_STORAGE_ACCOUNT="$AZURE_STORAGE_ACCOUNT"
export AZURE_STORAGE_KEY="$AZURE_STORAGE_KEY"

required_commands="kubectl base64 az"
for command in $required_commands; do
    if ! command -v "$command" >/dev/null 2>&1; then
        echo "error: required command not found: $command"
        exit 1
    fi
done

CLUSTER="$(kubectl config current-context)"
MAIN_NAME="migrate-psql-$CLUSTER"
DIR_DUMP="$MAIN_NAME"
CONTAINER_NAME="$MAIN_NAME"

echo "Checking storage targets..."
CONTAINER_EXISTS=$(az storage container exists --account-name "$AZURE_STORAGE_ACCOUNT" --account-key "$AZURE_STORAGE_KEY" --name "$CONTAINER_NAME" --query "exists" -o tsv 2>/dev/null)

if [ "$CONTAINER_EXISTS" = "true" ]; then
    echo "INFO: Remote Azure Storage Container '$CONTAINER_NAME' exists. Using it."
else
    echo "Creating Azure Storage Container '$CONTAINER_NAME'..."
    az storage container create \
        --account-name "$AZURE_STORAGE_ACCOUNT" \
        --account-key "$AZURE_STORAGE_KEY" \
        --name "$CONTAINER_NAME" \
        --output none
fi

if [ ! -d "$DIR_DUMP" ]; then
    mkdir -p "$DIR_DUMP"
else
    echo "INFO: Local directory '$DIR_DUMP' exists. Using it."
fi

get_databases() {
    local ns=$1
    local pod=$2
    local username=$3
    local password=$4
    local target_db=$5

    if [ "$target_db" != 'all' ]; then
        echo "$target_db"
        return
    fi

    kubectl exec -n "$ns" "$pod" -c postgresql -- env PGPASSWORD="$password" psql -U "$username" -d postgres -t -A -c \
        "SELECT datname FROM pg_database WHERE datistemplate = false AND datname NOT IN ('postgres');"
}

dump_psql() {
    local ns=$1
    local pod=$2
    local username=$3
    local password=$4
    local db=$5
    local blob_name=$6

    local blob_exists=$(az storage blob exists \
        --account-name "$AZURE_STORAGE_ACCOUNT" \
        --account-key "$AZURE_STORAGE_KEY" \
        --container-name "$CONTAINER_NAME" \
        --name "$blob_name" \
        --query "exists" -o tsv 2>/dev/null)

    if [ "$blob_exists" = "true" ]; then
        echo " -> WARNING: Database dump '$blob_name' already exists in Azure Storage. Skipping to avoid overwrite."
        return 0
    fi

    local local_tmp_dump="$DIR_DUMP/_tmp_dump.sql"

    kubectl exec -n "$ns" "$pod" -c postgresql -- env PGPASSWORD="$password" pg_dump -U "$username" -d "$db" --no-owner --clean > "$local_tmp_dump"

    az storage blob upload \
        --account-name "$AZURE_STORAGE_ACCOUNT" \
        --account-key "$AZURE_STORAGE_KEY" \
        --container-name "$CONTAINER_NAME" \
        --name "$blob_name" \
        --file "$local_tmp_dump" \
        --overwrite true \
        --output none

    rm -f "$local_tmp_dump"
}

if [ "$TARGET_NAMESPACE" = "all" ]; then
    echo "Retrieving all PostgreSQL on the cluster..."
    all_ns="$(kubectl get ns -o jsonpath='{.items[*].metadata.name}')"
else
    echo "Retrieving PostgreSQL in namespace: $TARGET_NAMESPACE..."
    all_ns="$TARGET_NAMESPACE"
fi

for ns in $all_ns; do
    ns_pods="$(kubectl get pods -n $ns -l '!cnpg.io/cluster' -o jsonpath='{.items[*].metadata.name}' 2>/dev/null)"
    
    for pod in $ns_pods; do
        if echo "$pod" | grep -q "sql" && ! echo "$pod" | grep -q "init"; then
            
            psql_username=''
            psql_password=''
            psql_database=''

            if echo "$ns" | grep -q "tenant"; then
                psql_password="$(kubectl get secret -n $ns postgresql-config -o jsonpath='{.data.postgres-password}' | base64 -d)"
                psql_username='postgres'
                psql_database='all'
            elif echo "$ns" | grep -q "keycloak"; then
                psql_password="$(kubectl get secret -n $ns keycloak-config -o jsonpath='{.data.keycloak_postgres_admin_password}' | base64 -d)"
                psql_username='postgres'
                psql_database='all'
            elif echo "$ns" | grep -q "harbor"; then
                psql_password="$(kubectl get secret -n $ns harbor-config -o jsonpath='{.data.harbor_postgres_admin_password}' | base64 -d)"
                psql_username='postgres'
                psql_database='all'
            elif echo "$ns" | grep -q "superset"; then
                psql_password="$(kubectl get secret -n $ns superset-postgresql -o jsonpath='{.data.password}' | base64 -d)"
                psql_username='bn_superset'
                psql_database='bitnami_superset'
            fi

            if [ -z "$psql_username" ]; then
                continue
            fi

            echo -e "\nFetching databases for $ns/$pod..."
            databases=$(get_databases "$ns" "$pod" "$psql_username" "$psql_password" "$psql_database")

            for db in $databases; do
                blob_path="$ns/$db.sql"
                echo "Dumping and uploading database '$db' from $ns/$pod to Azure Storage ($CONTAINER_NAME/$blob_path)..."
                dump_psql "$ns" "$pod" "$psql_username" "$psql_password" "$db" "$blob_path"
            done
        fi
    done
done

echo -e "\n=== Dump operation completed successfully ==="
exit 0