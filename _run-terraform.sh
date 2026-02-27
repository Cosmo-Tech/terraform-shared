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
target_file="target.tf"

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

      locals {
        cloud_identity = { \"azure.workload.identity/client-id\" = null }
        lb_annotations = {
          \"service.beta.kubernetes.io/azure-load-balancer-resource-group\"            = data.azurerm_kubernetes_cluster.cluster.node_resource_group
          \"service.beta.kubernetes.io/azure-load-balancer-health-probe-request-path\" = \"/healthz\"
        }
        lb_ip = data.azurerm_public_ip.lb_ip.ip_address
      }


      module \"storage_azure\" {
        source = \"git::https://github.com/cosmo-tech/terraform-azure.git//terraform-cluster/modules/storage\"

        for_each = var.cloud_provider == \"azure\" ? local.persistences : {}

        namespace          = each.value.namespace
        resource           = each.value.name
        size               = each.value.size
        resource_group     = data.azurerm_kubernetes_cluster.cluster.node_resource_group
        storage_class_name = local.storage_class_name
        region             = var.cluster_region
        cloud_provider     = var.cloud_provider
      }

    " > "$target_file";;

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

      locals {
        cloud_identity = \"eks.amazonaws.com/role-arn\" = data.terraform_remote_state.terraform_cluster.outputs.aws_irsa_role_arn }
        lb_annotations = {
          \"service.beta.kubernetes.io/aws-load-balancer-type\"                              = \"nlb\"
          \"service.beta.kubernetes.io/aws-load-balancer-backend-protocol\"                  = \"tcp\"
          \"service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled\" = \"true\"
          \"service.beta.kubernetes.io/aws-load-balancer-eip-allocations\"                   = \"eipalloc-03e2805bc83e3b481\"
          \"service.beta.kubernetes.io/aws-load-balancer-scheme\"                            = \"internet-facing\"
          \"service.beta.kubernetes.io/aws-load-balancer-subnets\"                           = \"subnet-02b5d6e252d7f60e7\"
        }
        lb_ip = null
      }


      module \"storage_aws\" {
        source = \"git::https://github.com/cosmo-tech/terraform-aws.git//terraform-cluster/modules/storage\"

        for_each = var.cloud_provider == \"aws\" ? local.persistences : {}

        namespace          = each.value.namespace
        resource           = \"\${var.cluster_name}-\${each.key}\"
        size               = each.value.size
        storage_class_name = local.storage_class_name
        region             = var.cluster_region
        cluster_name       = var.cluster_name
        cloud_provider     = var.cloud_provider
      }

    " > "$target_file";;

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

      locals {
        cloud_identity = { \"iam.gke.io/gcp-service-account\" = data.terraform_remote_state.terraform_cluster.outputs.node_sa_email }
        lb_annotations = {
          \"service.beta.kubernetes.io/google-load-balancer-ip\" = data.terraform_remote_state.terraform_cluster.outputs.platform_lb_ip
        }
        lb_ip = data.terraform_remote_state.terraform_cluster.outputs.platform_lb_ip
      }

      module \"storage_gcp\" {
        source = \"git::https://github.com/cosmo-tech/terraform-gcp.git//terraform-cluster/modules/storage\"

        for_each = var.cloud_provider == \"gcp\" ? local.persistences : {}

        namespace          = each.value.namespace
        resource           = \"\${var.cluster_name}-\${each.key}\"
        size               = each.value.size
        storage_class_name = local.storage_class_name
        region             = var.cluster_region
        cluster_name       = var.cluster_name
        cloud_provider     = var.cloud_provider
      }

    " > "$target_file";;

  'kob')
    echo " \
      terraform {
        backend \"local\" {
          path = \"terraform.tfstate\"
        }
      }

      locals {
        cloud_identity = {}
        lb_annotations = {}
        lb_ip = null
      }

      module \"storage_kob\" {
        # source = \"git::https://github.com/cosmo-tech/terraform-onprem.git//terraform-cluster/modules/storage\"
        source = \"git::https://github.com/cosmo-tech/terraform-onprem//terraform-cluster/modules/storage?ref=standardization\"

        for_each = var.cloud_provider == \"kob\" ? local.persistences : {}

        namespace          = each.value.namespace
        resource           = \"\${var.cluster_name}-\${each.key}\"
        size               = each.value.size
        storage_class_name = local.storage_class_name
        region             = var.cluster_region
        cloud_provider     = var.cloud_provider
      }

    " > "$target_file";;

  *)
    echo "error: unknown or empty \e[91mcloud_provider\e[0m from terraform.tfvars"
    exit
    ;;
esac


# Deploy
terraform fmt "$target_file"
terraform init -upgrade -reconfigure
terraform plan -out .terraform.plan
# terraform apply .terraform.plan


exit 0