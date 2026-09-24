#!/bin/sh

AZURE_STORAGE_ACCOUNT=""
AZURE_STORAGE_KEY=""
NAMESPACE="keycloak"
APP_USER="keycloak"

usage() {
    echo "Usage: $0 -s <storage_account_name> -k <storage_account_key>"
    exit 1
}

while [ $# -gt 0 ]; do
    case "$1" in
        -s|-sa-name|--sa-name)
            AZURE_STORAGE_ACCOUNT="$2"; shift 2 ;;
        -k|-sa-key|--sa-key)
            AZURE_STORAGE_KEY="$2"; shift 2 ;;
        *) usage ;;
    esac
done

if [ -z "$AZURE_STORAGE_ACCOUNT" ] || [ -z "$AZURE_STORAGE_KEY" ]; then
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

echo -e "\n=== Starting Keycloak Restore Process ==="

# 1. Verify CNPG cluster
CLUSTER_NAME=$(kubectl get clusters.postgresql.cnpg.io -n "$NAMESPACE" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
[ -z "$CLUSTER_NAME" ] && { echo "ERROR: No CNPG cluster found in $NAMESPACE"; exit 1; }

PRIMARY_POD=$(kubectl get pod -n "$NAMESPACE" -l "cnpg.io/cluster=$CLUSTER_NAME,role=primary" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
[ -z "$PRIMARY_POD" ] && { echo "ERROR: No primary CNPG pod found in $NAMESPACE"; exit 1; }

SUPER_PWD=$(kubectl get secret -n "$NAMESPACE" "${CLUSTER_NAME}-superuser" -o jsonpath='{.data.password}' | base64 -d)
SUPER_USER=$(kubectl get secret -n "$NAMESPACE" "${CLUSTER_NAME}-superuser" -o jsonpath='{.data.username}' | base64 -d)

# Search for the Keycloak backup on Azure (taking the first SQL file found)
BLOB_PATH=$(az storage blob list --account-name "$AZURE_STORAGE_ACCOUNT" --account-key "$AZURE_STORAGE_KEY" --container-name "$CONTAINER_NAME" --prefix "$NAMESPACE/" --query "[0].name" -o tsv)
[ -z "$BLOB_PATH" ] && { echo "ERROR: No dump file found in Azure Storage for $NAMESPACE"; exit 1; }

DB_NAME=$(basename "$BLOB_PATH" .sql)
LOCAL_DUMP="$DIR_DUMP/_tmp_keycloak_restore.sql"

echo " -> Downloading $BLOB_PATH from Azure Storage..."
az storage blob download --account-name "$AZURE_STORAGE_ACCOUNT" --account-key "$AZURE_STORAGE_KEY" --container-name "$CONTAINER_NAME" --name "$BLOB_PATH" --file "$LOCAL_DUMP" --output none

# 2. Safety first: Scale down the application
echo " -> Scaling down Keycloak application..."
kubectl scale statefulset keycloak -n "$NAMESPACE" --replicas=0 >/dev/null 2>&1 || kubectl scale deployment keycloak -n "$NAMESPACE" --replicas=0 >/dev/null 2>&1

# Wait for the pod to fully terminate to release database locks
sleep 10 

# 3. Database preparation (Force drop & Recreate)
echo " -> Dropping and recreating database '$DB_NAME'..."
kubectl exec -i -n "$NAMESPACE" "$PRIMARY_POD" -c postgres -- env PGPASSWORD="$SUPER_PWD" psql -h 127.0.0.1 -U "$SUPER_USER" -d postgres -c "DROP DATABASE IF EXISTS \"$DB_NAME\" WITH (FORCE);" >/dev/null 2>&1
kubectl exec -i -n "$NAMESPACE" "$PRIMARY_POD" -c postgres -- env PGPASSWORD="$SUPER_PWD" psql -h 127.0.0.1 -U "$SUPER_USER" -d postgres -c "CREATE DATABASE \"$DB_NAME\" OWNER \"$APP_USER\";" >/dev/null 2>&1

# 4. Data import
echo " -> Importing dump into '$DB_NAME'..."
kubectl exec -i -n "$NAMESPACE" "$PRIMARY_POD" -c postgres -- env PGPASSWORD="$SUPER_PWD" psql -h 127.0.0.1 -U "$SUPER_USER" -d "$DB_NAME" < "$LOCAL_DUMP" >/dev/null 2>&1

# 5. Fix table ownership and unlock Liquibase migrations
echo " -> Fixing table ownership and unlocking migrations..."
kubectl exec -i -n "$NAMESPACE" "$PRIMARY_POD" -c postgres -- env PGPASSWORD="$SUPER_PWD" psql -h 127.0.0.1 -U "$SUPER_USER" -d "$DB_NAME" >/dev/null 2>&1 <<EOF
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

UPDATE databasechangeloglock SET locked = false;
EOF

# 6. Scale back up
echo " -> Scaling back up Keycloak application..."
kubectl scale statefulset keycloak -n "$NAMESPACE" --replicas=1 >/dev/null 2>&1 || kubectl scale deployment keycloak -n "$NAMESPACE" --replicas=1 >/dev/null 2>&1

rm -f "$LOCAL_DUMP"
echo -e "\n=== Restore process completed successfully! ==="
exit 0