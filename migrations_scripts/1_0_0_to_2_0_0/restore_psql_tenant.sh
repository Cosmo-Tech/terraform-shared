#!/bin/sh

# set -x

AZURE_STORAGE_ACCOUNT=""
AZURE_STORAGE_KEY=""
NAMESPACE=""

usage() {
    echo "Usage: $0 -n <namespace> -s <storage_account_name> -k <storage_account_key>"
    exit 1
}

while [ $# -gt 0 ]; do
    case "$1" in
        -n|-namespace|--namespace)
            NAMESPACE="$2"; shift 2 ;;
        -s|-sa-name|--sa-name)
            AZURE_STORAGE_ACCOUNT="$2"; shift 2 ;;
        -k|-sa-key|--sa-key)
            AZURE_STORAGE_KEY="$2"; shift 2 ;;
        *) usage ;;
    esac
done

if [ -z "$AZURE_STORAGE_ACCOUNT" ] || [ -z "$AZURE_STORAGE_KEY" ] || [ -z "$NAMESPACE" ]; then
    usage
fi

export AZURE_STORAGE_ACCOUNT
export AZURE_STORAGE_KEY

for cmd in kubectl base64 az; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "error: required command not found: $cmd"
        exit 1
    fi
done

CLUSTER="$(kubectl config current-context)"
CONTAINER_NAME="migrate-psql-$CLUSTER"
DIR_DUMP="$CONTAINER_NAME"
mkdir -p "$DIR_DUMP"

echo -e "\n=== Starting Tenant Restore Process for namespace: $NAMESPACE ==="

# Verify CNPG cluster
CLUSTER_NAME=$(kubectl get clusters.postgresql.cnpg.io -n "$NAMESPACE" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
[ -z "$CLUSTER_NAME" ] && { echo "ERROR: No CNPG cluster found in $NAMESPACE"; exit 1; }

PRIMARY_POD=$(kubectl get pod -n "$NAMESPACE" -l "cnpg.io/cluster=$CLUSTER_NAME,role=primary" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
[ -z "$PRIMARY_POD" ] && { echo "ERROR: No primary CNPG pod found in $NAMESPACE"; exit 1; }

SUPER_USER=$(kubectl get secret -n "$NAMESPACE" "${CLUSTER_NAME}-superuser" -o jsonpath='{.data.username}' | base64 -d)




# Scale down to avoid data corruption during psql restoration
echo " -> Scaling down all applications in $NAMESPACE..."
for dep in $(kubectl get deployments -n "$NAMESPACE" -o jsonpath='{.items[*].metadata.name}' 2>/dev/null); do
    if ! echo "$dep" | grep -Eq "postgres|cnpg"; then
        kubectl scale deployment -n "$NAMESPACE" "$dep" --replicas=0 >/dev/null 2>&1
    fi
done
for sts in $(kubectl get statefulsets -n "$NAMESPACE" -o jsonpath='{.items[*].metadata.name}' 2>/dev/null); do
    if ! echo "$sts" | grep -Eq "postgres|cnpg"; then
        kubectl scale statefulset -n "$NAMESPACE" "$sts" --replicas=0 >/dev/null 2>&1
    fi
done

echo " -> Waiting for pods to terminate (15s)..."
sleep 15




# Fetch all SQL dumps for this tenant from Azure
BLOBS=$(az storage blob list --account-name "$AZURE_STORAGE_ACCOUNT" --account-key "$AZURE_STORAGE_KEY" --container-name "$CONTAINER_NAME" --prefix "$NAMESPACE/" --query "[].name" -o tsv)
[ -z "$BLOBS" ] && { echo "ERROR: No dump files found in Azure Storage for $NAMESPACE"; exit 1; }

for BLOB_PATH in $BLOBS; do
    DB_NAME=$(basename "$BLOB_PATH" .sql)
    LOCAL_DUMP="$DIR_DUMP/_tmp_${DB_NAME}_restore.sql"
    
    # Map the correct owner based on the database name
    APP_USER="postgres"
    case "$DB_NAME" in
        argo)      APP_USER="argo" ;;
        cosmotech) APP_USER="cosmotech_api_admin" ;;
        seaweedfs) APP_USER="seaweedfs" ;;
    esac

    echo "Processing database: $DB_NAME (Owner: $APP_USER)"
    
    echo " -> Downloading $BLOB_PATH..."
    az storage blob download --account-name "$AZURE_STORAGE_ACCOUNT" --account-key "$AZURE_STORAGE_KEY" --container-name "$CONTAINER_NAME" --name "$BLOB_PATH" --file "$LOCAL_DUMP" --output none

    # Ensure the role exists before creating the database (ignores error if already exists)
    kubectl exec -i -n "$NAMESPACE" "$PRIMARY_POD" -c postgres -- psql -U "$SUPER_USER" -d postgres -c "CREATE ROLE \"$APP_USER\" WITH LOGIN;" >/dev/null 2>&1

    echo " -> Dropping and recreating database '$DB_NAME'..."
    kubectl exec -i -n "$NAMESPACE" "$PRIMARY_POD" -c postgres -- psql -U "$SUPER_USER" -d postgres -c "DROP DATABASE IF EXISTS \"$DB_NAME\" WITH (FORCE);" >/dev/null 2>&1
    kubectl exec -i -n "$NAMESPACE" "$PRIMARY_POD" -c postgres -- psql -U "$SUPER_USER" -d postgres -c "CREATE DATABASE \"$DB_NAME\" OWNER \"$APP_USER\";" >/dev/null 2>&1

    echo " -> Importing data..."
    kubectl exec -i -n "$NAMESPACE" "$PRIMARY_POD" -c postgres -- psql -U "$SUPER_USER" -d "$DB_NAME" -q < "$LOCAL_DUMP"

    echo " -> Fixing table ownership..."
    kubectl exec -i -n "$NAMESPACE" "$PRIMARY_POD" -c postgres -- psql -U "$SUPER_USER" -d "$DB_NAME" >/dev/null 2>&1 <<EOF
ALTER SCHEMA public OWNER TO $APP_USER;

DO \$\$
DECLARE
    r RECORD;
BEGIN
    FOR r IN SELECT tablename FROM pg_tables WHERE schemaname = 'public' LOOP
        EXECUTE 'ALTER TABLE public.' || quote_ident(r.tablename) || ' OWNER TO $APP_USER;';
    END LOOP;
    FOR r IN SELECT sequencename FROM pg_sequences WHERE schemaname = 'public' LOOP
        EXECUTE 'ALTER SEQUENCE public.' || quote_ident(r.sequencename) || ' OWNER TO $APP_USER;';
    END LOOP;
END \$\$;
EOF

    rm -f "$LOCAL_DUMP"
done



# Get decoded value of a given secret key
# get_secret_value <namespace> <secret> <key>
get_secret_value() {
    local ns="$1"
    local secret="$2"
    local key="$3"

    kubectl -n $ns get secret $secret -o yaml | yq -r '.data | map_values(. | @base64d)' | yq .$key
}


# Replace a given key value in a Kubernetes secret
# Usage: replace_secret_key_value <secret> <key> <new_value>
replace_secret_key_value() {
    local secret=$1
    local key=$2
    local new_value=$3

    echo "Replacing value of secret key: $secret/$key with '$new_value'..."
    kubectl -n $NAMESPACE patch secret $secret -p '{"data": {"'$key'": "'$(echo -n "$new_value" | base64)'"}}'
}


# Get the list of all the PostgreSQL schemas used for the cosmotech tenant
# Usage: list_psql_cosmotech_schemas
list_psql_cosmotech_schemas() {
    # artificially add the "inputs" schema
    echo 'inputs'
    
    # All workspaces schemas
    kubectl exec -i -n "$NAMESPACE" "$PRIMARY_POD" -c postgres -- psql -U "$SUPER_USER" -d cosmotech -c "SELECT schema_name FROM information_schema.schemata;" | grep 'w_' | tr -d ' '
}


# Replace the owner of a given PostgreSQL schema
# Usage: replace_psql_schema_owner <schema> <new_owner>
replace_psql_schema_owner() {
    local schema=$1
    local new_owner=$2

    echo "Replacing schema '$schema' owner with '$new_owner'..."
    kubectl exec -i -n "$NAMESPACE" "$PRIMARY_POD" -c postgres -- psql -U "$SUPER_USER" -d cosmotech -c "ALTER SCHEMA $schema OWNER TO $new_owner;"
}


# Replace the password of a given PostgreSQL user
# Usage: replace_psql_user_password <username_target> <password_new>
replace_psql_user_password() {
    local username_target="$1"
    local password_new="$2"

    echo "Replacing password of user '$username_target'..."
    kubectl exec -i -n "$NAMESPACE" "$PRIMARY_POD" -c postgres -- psql -U "$SUPER_USER" -c "ALTER USER $username_target WITH PASSWORD '$password_new';"
}


# Get the list of CoAL Kubernetes secrets
# Usage: list_coal_secret_pqsl_password
list_coal_secret_pqsl_password() {
    kubectl -n $NAMESPACE get secret -o yaml | yq .items[].metadata.name | grep 'o-' | grep 'w-'
}


PSQL_SECRET='postgresql-cosmotechapi'
psql_admin_username="$(get_secret_value $NAMESPACE $PSQL_SECRET "admin-username")"
psql_admin_password="$(get_secret_value $NAMESPACE $PSQL_SECRET "admin-password")"

psql_writer_username="$(get_secret_value $NAMESPACE $PSQL_SECRET "writer-username")"
psql_writer_password="$(get_secret_value $NAMESPACE $PSQL_SECRET "writer-password")"

psql_reader_username="$(get_secret_value $NAMESPACE $PSQL_SECRET "reader-username")"
psql_reader_password="$(get_secret_value $NAMESPACE $PSQL_SECRET "reader-password")"

echo ''
echo "psql_admin_username $psql_admin_username"
echo "psql_admin_password $psql_admin_password"
echo ''
echo "psql_writer_username $psql_writer_username"
echo "psql_writer_password $psql_writer_password"
echo ''
echo "psql_reader_username $psql_reader_username"
echo "psql_reader_password $psql_reader_password"
echo ''


# Ensure schema owner are ok in the restored database
SCHEMA_LIST="$(list_psql_cosmotech_schemas)"
for schema in $SCHEMA_LIST; do
    replace_psql_schema_owner $schema $psql_writer_username
done


# Ensure passwords are ok in the restored database
replace_psql_user_password $psql_admin_username "$psql_admin_password"
replace_psql_user_password $psql_writer_username "$psql_writer_password"
replace_psql_user_password $psql_reader_username "$psql_reader_password"
## test the connexion : 
## psql -U cosmotech_api_admin --password -d cosmotech -h 127.0.0.1
## psql -U cosmotech_api_writer --password -d cosmotech -h 127.0.0.1
## psql -U cosmotech_api_reader --password -d cosmotech -h 127.0.0.1


# Ensure CoAL password are ok in all CoAL secrets (overwrite with cosmotech_api_writer)
COAL_SECRET_LIST="$(list_coal_secret_pqsl_password)"
for secret in $COAL_SECRET_LIST; do
    replace_secret_key_value $secret 'POSTGRES_USER_PASSWORD' $psql_writer_password
done




# Scale back up
echo -e "\n -> Scaling back up all applications in $NAMESPACE..."
for dep in $(kubectl get deployments -n "$NAMESPACE" -o jsonpath='{.items[*].metadata.name}' 2>/dev/null); do
    if ! echo "$dep" | grep -Eq "postgres|cnpg"; then
        kubectl scale deployment -n "$NAMESPACE" "$dep" --replicas=1 >/dev/null 2>&1
    fi
done
for sts in $(kubectl get statefulsets -n "$NAMESPACE" -o jsonpath='{.items[*].metadata.name}' 2>/dev/null); do
    if ! echo "$sts" | grep -Eq "postgres|cnpg"; then
        kubectl scale statefulset -n "$NAMESPACE" "$sts" --replicas=1 >/dev/null 2>&1
    fi
done


echo "\n=== Tenant restore process completed successfully for $NAMESPACE! ==="

exit 0