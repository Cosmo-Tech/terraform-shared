Before running terraform apply:
* `./dump_psql.sh -s <az_account_name> -k <az_account_key>`
  * automatically detect all running psql on the Kubernetes cluster and dump all databases to an Azure Storage Account
  * requires an Azure Storage account (with an access key)

After running terraform apply:
* `restore_psql_superset.sh -s <az_account_name> -k <az_account_key>`
* `restore_psql_keycloak.sh -s <az_account_name> -k <az_account_key>`
* `restore_psql_harbor.sh -s <az_account_name> -k <az_account_key>`
* `restore_psql_tenant.sh -s <az_account_name> -k <az_account_key> -n <namespace>`
