terraform {
  backend "azurerm" {
    resource_group_name  = "cosmotechstates"
    storage_account_name = "cosmotechstates"
    container_name       = "cosmotechstates"
    key                  = "tfstate-shared-aks-dev-devops3"
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
    resource_group_name  = "cosmotechstates"
    storage_account_name = "cosmotechstates"
    container_name       = "cosmotechstates"
    key                  = "tfstate-cluster-aks-dev-devops3"
  }
}

# Trick to get the resource group of the cluster (get it from instanciated Kubernetes nodes)
data "kubernetes_nodes" "selected" {
  metadata {
    labels = {
      "cosmotech.com/tier" = "db"
    }
  }
}

data "azurerm_public_ip" "lb_ip" {
  name                = "aks-dev-devops3-lb-ip"
  resource_group_name = [for node in data.kubernetes_nodes.selected.nodes : node.metadata.0.labels].0["kubernetes.azure.com/cluster"]
}

data "azurerm_client_config" "current" {}

