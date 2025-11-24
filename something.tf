# data "google_client_config" "current" {}

# data "terraform_remote_state" "terraform_cluster" {
#   backend = var.backend_state

#   config = var.backend_state == "gcs" ? {
#     bucket = "cosmotech-states"
#     prefix = var.backend_state_prefix
#     } : var.backend_state == "s3" ? {
#     bucket = "cosmotech-states"
#     key    = var.backend_state_prefix
#     region = var.region
#     } : var.backend_state == "azurerm" ? {
#     storage_account_name = "cosmotech-states"
#     container_name       = "terraform-state"
#     key                  = var.backend_state_prefix
#   } : {}
# }
