#!/bin/sh

AZURE_STORAGE_ACCOUNT=""
AZURE_STORAGE_KEY=""

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

export AZURE_STORAGE_ACCOUNT="$AZURE_STORAGE_ACCOUNT"
export AZURE_STORAGE_KEY="$AZURE_STORAGE_KEY"

# Added kubectl to the list of required commands to fetch the cluster context
required_commands="kubectl az curl python3 grep"
for command in $required_commands; do
    if ! command -v "$command" >/dev/null 2>&1; then
        echo "Error: required command not found: $command"
        exit 1
    fi
done

echo "Detecting current Kubernetes cluster context..."
CLUSTER="$(kubectl config current-context 2>/dev/null)"

if [ -z "$CLUSTER" ]; then
    echo "Error: Could not determine the current Kubernetes context. Check your kubeconfig."
    exit 1
fi

CONTAINER_NAME="migrate-psql-$CLUSTER"
echo "Target container resolved to: '$CONTAINER_NAME'"

echo "Generating temporary SAS token for container '$CONTAINER_NAME'..."
# Generate an expiry date 1 hour from now in the exact ISO 8601 format Azure expects
EXPIRY=$(python3 -c "from datetime import datetime, timedelta; print((datetime.utcnow() + timedelta(hours=1)).strftime('%Y-%m-%dT%H:%MZ'))")

SAS_TOKEN=$(az storage container generate-sas \
    --account-name "$AZURE_STORAGE_ACCOUNT" \
    --account-key "$AZURE_STORAGE_KEY" \
    --name "$CONTAINER_NAME" \
    --permissions r \
    --expiry "$EXPIRY" \
    --output tsv)

if [ -z "$SAS_TOKEN" ]; then
    echo "Error: Failed to generate SAS token. Check your credentials and container existence."
    exit 1
fi

echo "Fetching list of .sql blobs in container '$CONTAINER_NAME'..."
# Only list files ending with .sql
BLOBS=$(az storage blob list \
    --account-name "$AZURE_STORAGE_ACCOUNT" \
    --account-key "$AZURE_STORAGE_KEY" \
    --container-name "$CONTAINER_NAME" \
    --query "[?ends_with(name, '.sql')].name" \
    --output tsv)

if [ -z "$BLOBS" ]; then
    echo "No .sql files found in container '$CONTAINER_NAME'."
    exit 0
fi

TOTAL=0
SUCCESS=0
FAILED=0

echo "Starting validation (fetching only the last 500 bytes of each file)..."
echo "-------------------------------------------------------------------"

for BLOB in $BLOBS; do
    TOTAL=$((TOTAL + 1))
    
    # Construct the full URL with the SAS token for direct HTTP access
    URL="https://${AZURE_STORAGE_ACCOUNT}.blob.core.windows.net/${CONTAINER_NAME}/${BLOB}?${SAS_TOKEN}"

    # Use curl with the Range header (-r -500) to fetch ONLY the last 500 bytes of the blob.
    # This prevents downloading gigabytes of data just to check the end of the file.
    TAIL_CONTENT=$(curl -s -r -500 "$URL")

    # Check if the specific completion string is present in those last bytes
    if echo "$TAIL_CONTENT" | grep -q -- "-- PostgreSQL database dump complete"; then
        echo "[OK]      $BLOB"
        SUCCESS=$((SUCCESS + 1))
    else
        echo "[FAILED]  $BLOB (Missing completion string)"
        FAILED=$((FAILED + 1))
    fi
done

echo "-------------------------------------------------------------------"
echo "Validation Summary:"
echo "Total checked: $TOTAL"
echo "Successful:    $SUCCESS"
echo "Failed:        $FAILED"

if [ "$FAILED" -gt 0 ]; then
    echo "WARNING: Some database dumps appear to be incomplete."
    exit 1
else
    echo "SUCCESS: All database dumps are complete."
    exit 0
fi