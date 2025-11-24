provider "azurerm" {
  features {}
  subscription_id = var.azure_subscription_id
  tenant_id       = var.azure_entra_tenant_id
}
terraform {
  backend "azurerm" {
    key                  = "tfstate-shared-assetaip-dev"
    storage_account_name = "cosmotechstates"
    container_name       = "cosmotechstates"
    resource_group_name  = "cosmotechstates"
  }
}
variable "azure_subscription_id" { type = string }
variable "azure_entra_tenant_id" { type = string }
