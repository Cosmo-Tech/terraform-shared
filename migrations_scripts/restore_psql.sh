#!/bin/sh

# set -x

AZURE_STORAGE_ACCOUNT=$1
AZURE_STORAGE_KEY=$2
TARGET=$3

if [ -z "$AZURE_STORAGE_ACCOUNT" ] || [ -z "$AZURE_STORAGE_KEY" ] || [ -z "$TARGET" ]; then
    echo "usage: $0 <storage_account_name> <storage_account_key> <shared | namespace_name>"
    echo "examples:"
    echo "  $0 mystorageaccount mykey shared"
    echo "  $0 mystorageaccount mykey tenant-update"
    echo "  $0 mystorageaccount mykey tenant-update-pbi"
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

if [ ! -d "$DIR_DUMP" ]; then
    mkdir -p "$DIR_DUMP"
fi

TMP_FILE="$DIR_DUMP/_restore_$MAIN_NAME.yaml.tmp"

echo "Checking Azure Storage Container '$CONTAINER_NAME'..."
CONTAINER_EXISTS=$(az storage container exists --account-name "$AZURE_STORAGE_ACCOUNT" --account-key "$AZURE_STORAGE_KEY" --name "$CONTAINER_NAME" --query "exists" -o tsv 2>/dev/null)

if [ "$CONTAINER_EXISTS" != "true" ]; then
    echo "ERROR: Remote Azure Storage Container '$CONTAINER_NAME' does not exist."
    exit 1
fi

echo "Retrieving target PostgreSQL pods on cluster $CLUSTER..."

# Get all namespaces and filter strictly
all_cluster_ns="$(kubectl get ns -o yaml | yq '.items[].metadata.name')"
all_ns=""

if [ "$TARGET" = "shared" ]; then
    echo "Mode: Restoring shared services (keycloak, harbor, superset)"
    for ns in $all_cluster_ns; do
        if [ "$ns" = "keycloak" ] || [ "$ns" = "harbor" ] || [ "$ns" = "superset" ]; then
            all_ns="$all_ns $ns"
        fi
    done
else
    echo "Mode: Restoring namespace '$TARGET'"
    for ns in $all_cluster_ns; do
        if [ "$ns" = "$TARGET" ]; then
            all_ns="$ns"
            break
        fi
    done
fi

if [ -z "$all_ns" ]; then
    echo "ERROR: Namespace '$TARGET' not found on cluster"
    exit 1
fi

psql_pods=""
for ns in $all_ns; do
    ns_pods="$(kubectl get pods -n "$ns" -o yaml | yq '.items[].metadata.name')"
    for pod in $ns_pods; do
        if [ "$(echo "$pod" | grep sql)" ] && [ ! "$(echo "$pod" | grep 'init')" ]; then
            psql_pods="$psql_pods $ns/$pod"
        fi
    done
done

if [ -z "$psql_pods" ]; then
    echo "ERROR: No PostgreSQL pods found in target namespace(s)"
    exit 1
fi


echo "psql:" > "$TMP_FILE"
for filter in $psql_pods; do
    ns="$(echo "$filter" | cut -d/ -f1)"
    pod="$(echo "$filter" | cut -d/ -f2)"
    psql_username=''
    psql_password=''
    psql_database=''

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


# Get list of blob dumps available in Azure Storage for an namespace folder
# Usage: get_remote_blobs <namespace>
get_remote_blobs() {
    local ns=$1
    az storage blob list \
        --account-name "$AZURE_STORAGE_ACCOUNT" \
        --account-key "$AZURE_STORAGE_KEY" \
        --container-name "$CONTAINER_NAME" \
        --prefix "$ns/" \
        --query "[].name" -o tsv
}


# Download dump from Azure Storage to temporary file and restore into PostgreSQL
# Usage: restore_psql <namespace> <pod> <username> <password> <database> <blob_name>
restore_psql() {
    local ns=$1
    local pod=$2
    local username=$3
    local password=$4
    local db=$5
    local blob_name=$6

    local local_tmp_dump="$DIR_DUMP/_tmp_restore.sql"

    # 1. Download blob to local temp file
    echo "  -> Downloading $blob_name from Azure Storage..."
    az storage blob download \
        --account-name "$AZURE_STORAGE_ACCOUNT" \
        --account-key "$AZURE_STORAGE_KEY" \
        --container-name "$CONTAINER_NAME" \
        --name "$blob_name" \
        --file "$local_tmp_dump" \
        --output none

    if [ ! -f "$local_tmp_dump" ]; then
        echo "ERROR: Failed to download blob $blob_name"
        return 1
    fi

    # 2. Restore dump into PostgreSQL
    echo "  -> Restoring database '$db' into $ns/$pod..."
    kubectl exec -i -n "$ns" "$pod" -c postgresql -- env PGPASSWORD="$password" psql -U "$username" -d "$db" < "$local_tmp_dump"

    # 3. Cleanup local temp file
    rm -f "$local_tmp_dump"
}


# Execution of restore process
for i in $(yq -r '.psql | keys | .[]' "$TMP_FILE"); do
    ns=$(yq -r ".psql[$i].ns" "$TMP_FILE")
    pod=$(yq -r ".psql[$i].psql_pod" "$TMP_FILE")
    user=$(yq -r ".psql[$i].psql_username" "$TMP_FILE")
    pwd=$(yq -r ".psql[$i].psql_password" "$TMP_FILE")

    echo ''
    echo "Fetching dump files from Azure Storage for namespace '$ns'..."
    blobs=$(get_remote_blobs "$ns")

    if [ -z "$blobs" ]; then
        echo "WARNING: No dump files found in Azure Storage for namespace '$ns'"
        continue
    fi

    for blob_path in $blobs; do
        # Extract database name from blob filename (ns/db.sql -> db)
        db=$(basename "$blob_path" .sql)

        restore_psql "$ns" "$pod" "$user" "$pwd" "$db" "$blob_path"
    done
done


# Cleanup temporary YAML file
rm -f "$TMP_FILE"

echo ''
echo "Restore process completed!"
exit 0