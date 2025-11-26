#!/bin/sh

# Stop script if missing dependency
required_commands="terraform jq"
for command in $required_commands; do
    if [ -z "$(command -v $command)" ]; then
        echo "error: required command not found: \e[91m$command\e[97m"
        exit 1
    fi
done

# Get value of a variable declared in a given file from this pattern: variable = "value"
# Usage: get_var_value <file> <variable>
get_var_value() {
    local file=$1
    local variable=$2

    cat $file | grep '=' | grep -w $variable | sed '/.*#.*/d' | sed 's|.*=.*"\(.*\)".*|\1|' | head -n 1
}
cloud_provider="$(get_var_value terraform.tfvars cloud_provider)"
cluster_region="$(get_var_value terraform.tfvars cluster_region)"
cluster_name="$(get_var_value terraform.tfvars cluster_name)"
state_file_name="tfstate-shared-$cluster_name"


# Clear old data
rm -rf .terraform*
rm -rf terraform.tfstate*


# The trick here is to write configuration in a dynamic file created at the begin of the
# execution, containing the config that the concerned provider is waiting for Terraform backend.
# Then, Terraform will automatically detects it from its .tf extension.
backend_file="backend.tf"
case "$(echo $cloud_provider)" in
  'azure')
    state_storage_name='"cosmotechstates"'
    echo " \
        terraform {
            backend \"azurerm\" {
              resource_group_name    = $state_storage_name
              storage_account_name   = $state_storage_name
              container_name         = $state_storage_name
              key                    = \"$state_file_name\"
            }
        }

        provider \"azurerm\" {
          features {}
          subscription_id = var.azure_subscription_id
          tenant_id       = var.azure_entra_tenant_id
        }

        variable \"azure_subscription_id\" { type = string }
        variable \"azure_entra_tenant_id\" { type = string }

        data \"terraform_remote_state\" \"terraform_cluster\" {
          backend = \"azurerm\"
          config = {
            resource_group_name  = $state_storage_name
            storage_account_name = $state_storage_name
            container_name       = $state_storage_name
            key                  = \"tfstate-cluster-$cluster_name\"
          }
        }

        # Trick to get the resource group of the cluster (get it from instanciated Kubernetes nodes)
        data \"kubernetes_nodes\" \"selected\" {
          metadata {
            labels = {
              \"cosmotech.com/tier\" = \"db\"
            }
          }
        }

        data \"azurerm_public_ip\" \"lb_ip\" {
          name                  = \"$cluster_name-lb-ip\"
          resource_group_name   = [for node in data.kubernetes_nodes.selected.nodes : node.metadata.0.labels].0[\"kubernetes.azure.com/cluster\"]
        }

        data \"azurerm_client_config\" \"current\" {}
    " > $backend_file ;;

  'aws')
    state_storage_name='"cosmotech-states"'
    echo " \
        terraform {
          backend \"s3\" {
            key    = \"$state_file_name\"
            bucket = $state_storage_name
            region = \"$cluster_region\"
          }
        }

        provider \"aws\" {
          region = var.cluster_region
        }
    " > $backend_file ;;

  'gcp')
    state_storage_name='"cosmotech-states"'
    echo " \
        terraform {
          backend \"gcs\" {
            bucket = $state_storage_name
            prefix = "$state_file_name"
          }
        }

        provider \"google\" {
          project = var.project_id
          region  = var.cluster_region
        }

        variable \"project_id\" { type = string }

        data \"terraform_remote_state\" \"terraform_cluster\" {
          backend = \"gcs\"
          config = {
            bucket = $state_storage_name
            # prefix = \"\"
          }
        }

        data \"google_client_config\" \"current\" {}
    " > $backend_file ;;

  *)
    echo "error: unknown or empty \e[91mcloud_provider\e[0m from terraform.tfvars"
    exit
    ;;
esac


# Deploy
terraform fmt $backend_file
terraform init -upgrade -reconfigure
terraform plan -out .terraform.plan
# terraform apply .terraform.plan


exit 0