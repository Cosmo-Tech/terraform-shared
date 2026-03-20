terraform {
  backend "azurerm" {
    resource_group_name  = "$TEMPLATE_state_storage_name"
    storage_account_name = "$TEMPLATE_state_storage_name"
    container_name       = "$TEMPLATE_state_storage_name"
    key                  = "$TEMPLATE_state_file_name"
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.azure_subscription_id
  tenant_id       = var.azure_entra_tenant_id
}

variable "azure_subscription_id" { type = string }
variable "azure_entra_tenant_id" { type = string }

data "terraform_remote_state" "terraform_cluster" {
  backend = "azurerm"
  config = {
    resource_group_name  = "$TEMPLATE_state_storage_name"
    storage_account_name = "$TEMPLATE_state_storage_name"
    container_name       = "$TEMPLATE_state_storage_name"
    key                  = "tfstate-cluster-$TEMPLATE_cluster_name"
  }
}

data "azurerm_kubernetes_cluster" "cluster" {
  name                = "$TEMPLATE_cluster_name"
  resource_group_name = "$TEMPLATE_cluster_name"
}

data "azurerm_public_ip" "lb_ip" {
  name                = "$TEMPLATE_cluster_name-lb-ip"
  resource_group_name = data.azurerm_kubernetes_cluster.cluster.node_resource_group
}

data "azurerm_client_config" "current" {}

locals {
  cloud_identity = {
    "azure.workload.identity/client-id" = null
  }

  lb_annotations = {
    "service.beta.kubernetes.io/azure-load-balancer-resource-group"            = data.azurerm_kubernetes_cluster.cluster.node_resource_group
    "service.beta.kubernetes.io/azure-load-balancer-health-probe-request-path" = "/healthz"
  }

  lb_ip = data.azurerm_public_ip.lb_ip.ip_address
}

module "storage_azure" {
  source = "git::https://github.com/cosmo-tech/terraform-azure.git//terraform-cluster/modules/storage"

  for_each = var.cloud_provider == "azure" ? local.persistences : {}

  namespace          = each.value.namespace
  resource           = each.value.name
  size               = each.value.size
  resource_group     = data.azurerm_kubernetes_cluster.cluster.node_resource_group
  storage_class_name = local.storage_class_name
  region             = var.cluster_region
  cloud_provider     = var.cloud_provider
}