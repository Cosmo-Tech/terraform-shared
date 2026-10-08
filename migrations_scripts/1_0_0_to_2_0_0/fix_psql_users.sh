#!/bin/sh

# set -x


# Stop script if missing dependency
required_commands="kubectl base64 az"
for command in $required_commands; do
    if [ -z "$(command -v $command)" ]; then
        echo "error: required command not found: \e[91m$command\e[97m"
        exit
    fi
done


usage() {
    echo "Usage: $0 -n <namespace>"
    exit 1
}

while [ $# -gt 0 ]; do
    case "$1" in
        -n|-namespace|--namespace)
            NAMESPACE="$2"; shift 2 ;;
        *) usage ;;
    esac
done

if [ -z "$NAMESPACE" ]; then
    usage
fi


CNPG_CLUSTER="$(kubectl get clusters.postgresql.cnpg.io -n $NAMESPACE -o jsonpath='{.items[0].metadata.name}')"
if [ -z "$CNPG_CLUSTER" ]; then
    echo "error: no CNPG cluster found in $NAMESPACE"
    exit 1
fi

CNPG_POD="$(kubectl get pod -n "$NAMESPACE" -l "cnpg.io/cluster=$CNPG_CLUSTER,role=primary" -o jsonpath='{.items[0].metadata.name}')"
if [ -z "$CNPG_POD" ]; then
    echo "error: no primary CNPG pod found in $NAMESPACE"
    exit 1
fi

CNPG_SUPER_USER="$(kubectl get secret -n "$NAMESPACE" "${CNPG_CLUSTER}-superuser" -o jsonpath='{.data.username}' | base64 -d)"



# Shortcut to query SQL on CNPG pod
# Usage: kubectl_psql_cmd <payload>
kubectl_psql_cmd() {

    # Inline payload, just to complete the command with whatever SQL can support
    # example: '-d cosmotech' '-c "SQL QUERY"'
    # local payload="${args[@]}"
    # local payload=$*
    # local payload="$*"
    # local payload="$@"


    # echo $payload

    # echo $payload | kubectl exec -i -n "$NAMESPACE" "$CNPG_POD" -c postgres -- psql -U "$CNPG_SUPER_USER"

    kubectl exec -i -n "$NAMESPACE" "$CNPG_POD" -c postgres -- psql -U "$CNPG_SUPER_USER" "$@"
}


# Get decoded value of a given secret key
# get_secret_value <namespace> <secret> <key>
get_secret_value() {
    local ns="$1"
    local secret="$2"
    local key="$3"

    # kubectl -n $ns get secret $secret -o yaml | yq -r '.data | map_values(. | @base64d)' | yq .$key
    kubectl -n "$ns" get secret "$secret" -o jsonpath="{.data.$key}" | base64 -d
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
    # kubectl exec -i -n "$NAMESPACE" "$CNPG_POD" -c postgres -- psql -U "$CNPG_SUPER_USER" -d cosmotech -c "SELECT schema_name FROM information_schema.schemata;" | grep 'w_' | tr -d ' '
    kubectl_psql_cmd -d cosmotech -c "SELECT schema_name FROM information_schema.schemata;" | grep 'w_' | tr -d ' '
}


# Replace the owner of a given PostgreSQL schema
# Usage: replace_psql_schema_owner <schema> <new_owner>
replace_psql_schema_owner() {
    local schema=$1
    local new_owner=$2

    echo "Replacing schema '$schema' owner with '$new_owner'..."
    # kubectl exec -i -n "$NAMESPACE" "$CNPG_POD" -c postgres -- psql -U "$CNPG_SUPER_USER" -d cosmotech -c "ALTER SCHEMA $schema OWNER TO $new_owner;"
    kubectl_psql_cmd -d cosmotech -c "ALTER SCHEMA $schema OWNER TO $new_owner;"
}


# Create required PostgreSQL users for cosmotech
# Usage: create_psql_users
create_psql_users() {
    ADMIN_USER="$(get_secret_value $NAMESPACE $PSQL_SECRET "admin-username")"
    ADMIN_PASS="$(get_secret_value $NAMESPACE $PSQL_SECRET "admin-password")"

    WRITER_USER="$(get_secret_value $NAMESPACE $PSQL_SECRET "writer-username")"
    WRITER_PASS="$(get_secret_value $NAMESPACE $PSQL_SECRET "writer-password")"

    READER_USER="$(get_secret_value $NAMESPACE $PSQL_SECRET "reader-username")"
    READER_PASS="$(get_secret_value $NAMESPACE $PSQL_SECRET "reader-password")"


    kubectl_psql_cmd -c "CREATE $ADMIN_USER WITH LOGIN PASSWORD '$ADMIN_PASS' CREATEDB;"
    kubectl_psql_cmd -c "CREATE $WRITER_USER WITH LOGIN PASSWORD '$WRITER_PASS';"
    kubectl_psql_cmd -c "CREATE $READER_USER WITH LOGIN PASSWORD '$READER_PASS';"
    kubectl_psql_cmd -c "GRANT $WRITER_USER TO $ADMIN_USER;"
    kubectl_psql_cmd -c "GRANT $READER_USER TO $ADMIN_USER;"

    kubectl_psql_cmd -d cosmotech -c "GRANT USAGE ON SCHEMA inputs TO $READER_USER;"
    kubectl_psql_cmd -d cosmotech -c "ALTER DEFAULT PRIVILEGES IN SCHEMA inputs GRANT SELECT ON TABLES TO $READER_USER;"
}


# Replace the password of a given PostgreSQL user
# Usage: replace_psql_user_password <username_target> <password_new>
replace_psql_user_password() {
    local username_target="$1"
    local password_new="$2"

    echo "Replacing password of user '$username_target'..."
    # kubectl exec -i -n "$NAMESPACE" "$CNPG_POD" -c postgres -- psql -U "$CNPG_SUPER_USER" -c "ALTER USER $username_target WITH PASSWORD '$password_new';"
    kubectl_psql_cmd -c "ALTER USER $username_target WITH PASSWORD '$password_new';"
}


# Get the list of CoAL Kubernetes secrets
# Usage: list_coal_secret_pqsl_password
list_coal_secret_pqsl_password() {
    kubectl -n $NAMESPACE get secret -o yaml | yq .items[].metadata.name | grep 'o-' | grep 'w-'
}


psql_version="$(kubectl_psql_cmd -c "SELECT version();")"
echo "$psql_version"


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


# Ensure cosmotech users exists in psql
create_psql_users


# Ensure schemas owners are ok in the restored database
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


# Ensure CoAL passwords are ok in all CoAL secrets (overwrite with cosmotech_api_writer)
COAL_SECRET_LIST="$(list_coal_secret_pqsl_password)"
for secret in $COAL_SECRET_LIST; do
    replace_secret_key_value $secret 'POSTGRES_USER_PASSWORD' $psql_writer_password
done



# ARGO WORKFLOWS
PSQL_SECRET_ARGO='postgresql-argo'
psql_argo_username="$(get_secret_value $NAMESPACE $PSQL_SECRET_ARGO "database-username")"
psql_argo_password="$(get_secret_value $NAMESPACE $PSQL_SECRET_ARGO "database-password")"

replace_psql_user_password $psql_argo_username "$psql_argo_password"


# SEAWEEDFS
PSQL_SECRET_SEAWEEDFS='postgresql-seaweedfs'
psql_seaweedfs_username="$(get_secret_value $NAMESPACE $PSQL_SECRET_SEAWEEDFS "postgresql-username")"
psql_seaweedfs_password="$(get_secret_value $NAMESPACE $PSQL_SECRET_SEAWEEDFS "postgresql-password")"

replace_psql_user_password $psql_seaweedfs_username "$psql_seaweedfs_password"


exit
