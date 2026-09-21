#!/bin/sh

# set -x

AZURE_STORAGE_ACCOUNT=$1
AZURE_STORAGE_KEY=$2

if [ -z "$AZURE_STORAGE_ACCOUNT" ] || [ -z "$AZURE_STORAGE_KEY" ]; then
    echo "usage: $0 <storage_account_name> <storage_account_key>"
    exit 1
fi

# Export Azure credentials for sub-processes and CLI calls
export AZURE_STORAGE_ACCOUNT="$AZURE_STORAGE_ACCOUNT"
export AZURE_STORAGE_KEY="$AZURE_STORAGE_KEY"

# Stop script if missing dependency
required_commands="yq kubectl base64 az"
for command in $required_commands; do
    if [ -z "$(command -v $command)" ]; then
        echo "error: required command not found: \e[91m$command\e[97m"
        exit 1
    fi
done


CLUSTER="$(kubectl config current-context)"

MAIN_NAME="migrate-psql-$CLUSTER"
DIR_DUMP="$MAIN_NAME"
CONTAINER_NAME="$MAIN_NAME"

# Check Local Directory & Remote Azure Container
echo "Checking storage targets..."
CONTAINER_EXISTS=$(az storage container exists --account-name "$AZURE_STORAGE_ACCOUNT" --account-key "$AZURE_STORAGE_KEY" --name "$CONTAINER_NAME" --query "exists" -o tsv 2>/dev/null)

if [ "$CONTAINER_EXISTS" = "true" ]; then
    echo "WARNING: Remote Azure Storage Container '$CONTAINER_NAME' already exists."
fi

if [ -d "$DIR_DUMP" ]; then
    echo "WARNING: Local directory '$DIR_DUMP' already exists."
fi

# Exit if both exist to prevent unintended overwrite
if [ "$CONTAINER_EXISTS" = "true" ] && [ -d "$DIR_DUMP" ]; then
    echo "ERROR: Both local directory and Azure container already exist. Exiting to avoid conflicts."
    exit 1
fi

# Create container if it does not exist
if [ "$CONTAINER_EXISTS" != "true" ]; then
    echo "Creating Azure Storage Container '$CONTAINER_NAME'..."
    az storage container create \
        --account-name "$AZURE_STORAGE_ACCOUNT" \
        --account-key "$AZURE_STORAGE_KEY" \
        --name "$CONTAINER_NAME" \
        --output none
fi

# Create local directory if it does not exist
if [ ! -d "$DIR_DUMP" ]; then
    mkdir -p "$DIR_DUMP"
fi

TMP_FILE="$DIR_DUMP/_$MAIN_NAME.yaml.tmp"


echo 'Retrieving all PostgreSQL on the cluster...'

all_ns="$(kubectl get ns -o yaml | yq '.items[].metadata.name')"
for ns in $all_ns; do

    ns_pods="$(kubectl get pods -n $ns -o yaml | yq '.items[].metadata.name')"
    for pod in $ns_pods; do

        if [ "$(echo $pod | grep sql)" ] && [ ! "$(echo $pod | grep 'init')" ]; then
            psql_pods="$(echo $psql_pods $ns/$pod)"
        fi

    done
done



echo "psql:" > "$TMP_FILE"
for filter in $psql_pods; do
    ns="$(echo $filter | cut -d/ -f1)"
    pod="$(echo $filter | cut -d/ -f2)"
    psql_username=''
    psql_password=''
    psql_database=''

    # - psql_database='all'             => dump all databases
    # - psql_database=<database_name>   => dump the given database

    if  [ "$(echo $ns | grep tenant)" ]; then
        psql_password="$(kubectl get secret -n $ns postgresql-config -o yaml | yq '.data.postgres-password' | base64 -d)"
        psql_username='postgres'
        psql_database='all'
    fi

    if  [ "$(echo $ns | grep keycloak)" ]; then
        psql_password="$(kubectl get secret -n $ns keycloak-config -o yaml | yq '.data.keycloak_postgres_admin_password' | base64 -d)"
        psql_username='postgres'
        psql_database='all'
    fi

    if  [ "$(echo $ns | grep harbor)" ]; then
        psql_password="$(kubectl get secret -n $ns harbor-config -o yaml | yq '.data.harbor_postgres_admin_password' | base64 -d)"
        psql_username='postgres'
        psql_database='all'
    fi

    if  [ "$(echo $ns | grep superset)" ]; then
        psql_password="$(kubectl get secret -n $ns superset-postgresql -o yaml | yq '.data.password' | base64 -d)"
        psql_username='bn_superset'
        psql_database='bitnami_superset'
    fi

    echo "  - ns: $ns"                                 >> "$TMP_FILE"
    echo "    psql_pod: $pod"                           >> "$TMP_FILE"
    echo "    psql_username: $psql_username"            >> "$TMP_FILE"
    echo "    psql_password: $psql_password"            >> "$TMP_FILE"
    echo "    psql_database: $psql_database"            >> "$TMP_FILE"
done


if [ -f "$TMP_FILE" ]; then
    echo "$TMP_FILE successfully created !"
else
    echo "$TMP_FILE not created, exiting"
    exit 1
fi


# Get list of databases from a PostgreSQL pod
# Usage: get_databases <namespace> <pod> <username> <password> <target_db>
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


# Dump PostgreSQL database to temp file and upload using az cli
# Usage: dump_psql <namespace> <pod> <username> <password> <database> <blob_name>
dump_psql() {
    local ns=$1
    local pod=$2
    local username=$3
    local password=$4
    local db=$5
    local blob_name=$6

    local local_tmp_dump="$DIR_DUMP/_tmp_dump.sql"

    # 1. Dump to local temp file
    kubectl exec -n "$ns" "$pod" -c postgresql -- env PGPASSWORD="$password" pg_dump -U "$username" -d "$db" > "$local_tmp_dump"

    # 2. Upload file to Azure Storage
    az storage blob upload \
        --account-name "$AZURE_STORAGE_ACCOUNT" \
        --account-key "$AZURE_STORAGE_KEY" \
        --container-name "$CONTAINER_NAME" \
        --name "$blob_name" \
        --file "$local_tmp_dump" \
        --overwrite true \
        --output none

    # 3. Cleanup local temp file
    rm -f "$local_tmp_dump"
}


for i in $(yq -r '.psql | keys | .[]' "$TMP_FILE"); do
    ns=$(yq -r ".psql[$i].ns" "$TMP_FILE")
    pod=$(yq -r ".psql[$i].psql_pod" "$TMP_FILE")
    user=$(yq -r ".psql[$i].psql_username" "$TMP_FILE")
    pwd=$(yq -r ".psql[$i].psql_password" "$TMP_FILE")
    target_db=$(yq -r ".psql[$i].psql_database" "$TMP_FILE")

    echo ''
    echo "Fetching databases for $ns/$pod..."
    databases=$(get_databases "$ns" "$pod" "$user" "$pwd" "$target_db")

    for db in $databases; do
        blob_path="$ns/$db.sql"
        echo "Dumping and uploading database '$db' from $ns/$pod to Azure Storage ($CONTAINER_NAME/$blob_path)..."

        dump_psql "$ns" "$pod" "$user" "$pwd" "$db" "$blob_path"
    done
done


# rm -f $TMP_FILE


exit 0