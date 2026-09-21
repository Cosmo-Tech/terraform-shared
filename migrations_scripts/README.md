* dump_psql.sh
  * `./dump_psql.sh <az_account_name> <az_account_key>` => automatically detect all running psql on the Kubernetes cluster and dump all databases to an Azure Storage Account
  * requires an Azure Storage account (with an access key)

* restore_psql.sh
  * `./restore_psql.sh <az_account_name> <az_account_key> shared`    => to restore databases of all services that runs a psql from terraform-shared)
  * `./restore_psql.sh <az_account_name> <az_account_key> namespace` => to restore tenant databases
