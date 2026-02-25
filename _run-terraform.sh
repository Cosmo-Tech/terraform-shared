#!/bin/sh

# Script to run terraform modules
# Usage :
# - ./script.sh


# Stop script if missing dependency
required_commands="terraform"
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


# Prepare backend and locals files
backend_file="backend.tf"
locals_file="locals.tf"

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

        data "azurerm_kubernetes_cluster" "cluster" {
          name                = \"$cluster_name\"
          resource_group_name = \"$cluster_name\"
        }

        data \"azurerm_public_ip\" \"lb_ip\" {
          name                = \"$cluster_name-lb-ip\"
          resource_group_name = data.azurerm_kubernetes_cluster.cluster.node_resource_group
        }

        data \"azurerm_client_config\" \"current\" {}
    " > "$backend_file"

    # Generate locals.tf for Azure
    echo "locals {
  cloud_identity = { \"azure.workload.identity/client-id\" = null }

  lb_annotations = {
    \"service.beta.kubernetes.io/azure-load-balancer-resource-group\"            = [for node in data.kubernetes_nodes.selected.nodes : node.metadata.0.labels].0[\"kubernetes.azure.com/cluster\"]
    \"service.beta.kubernetes.io/azure-load-balancer-health-probe-request-path\" = \"/healthz\"
  }

  lb_ip = data.azurerm_public_ip.lb_ip.ip_address

  cluster_domain = \"${cluster_name}.${domain_zone}\"
}" > "$locals_file"
    ;;

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
    " > "$backend_file"

    # Generate locals.tf for AWS
    echo "locals {
  cloud_identity = { \"eks.amazonaws.com/role-arn\" = data.terraform_remote_state.terraform_cluster.outputs.aws_irsa_role_arn }

  lb_annotations = {
    \"service.beta.kubernetes.io/aws-load-balancer-type\"                              = \"nlb\"
    \"service.beta.kubernetes.io/aws-load-balancer-backend-protocol\"                  = \"tcp\"
    \"service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled\" = \"true\"
    \"service.beta.kubernetes.io/aws-load-balancer-eip-allocations\"                   = \"eipalloc-03e2805bc83e3b481\"
    \"service.beta.kubernetes.io/aws-load-balancer-scheme\"                            = \"internet-facing\"
    \"service.beta.kubernetes.io/aws-load-balancer-subnets\"                           = \"subnet-02b5d6e252d7f60e7\"
  }

  lb_ip = null

  cluster_domain = \"${cluster_name}.${domain_zone}\"
}" > "$locals_file"
    ;;

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
    " > "$backend_file"

    # Generate locals.tf for GCP
    echo "locals {
  cloud_identity = { \"iam.gke.io/gcp-service-account\" = data.terraform_remote_state.terraform_cluster.outputs.node_sa_email }

  lb_annotations = {
    \"service.beta.kubernetes.io/google-load-balancer-ip\" = data.terraform_remote_state.terraform_cluster.outputs.platform_lb_ip
  }

  lb_ip = data.terraform_remote_state.terraform_cluster.outputs.platform_lb_ip

  cluster_domain = \"${cluster_name}.${domain_zone}\"
}" > "$locals_file"
    ;;
  'kob')
    # generate backend.tf for kob (local backend)
    echo "terraform {
  backend \"local\" {
    path = \"terraform.tfstate\"
  }
}" > "$backend_file"  
    # generate empty locals.tf for kob
    echo "locals {
  cloud_identity = {}
  lb_annotations  = {}
  lb_ip          = ""
  cluster_domain  = \"${cluster_name}.${domain_zone}\"
}" > "$locals_file"
    ;;
  *)
esac


# Deploy
terraform fmt "$backend_file"
terraform fmt "$locals_file"
terraform init -upgrade -reconfigure
terraform plan -out .terraform.plan
# terraform apply .terraform.plan


exit 0