# Authentication to Image Registry is required to allow usage of sub-images in Charts
# - This secret intends to be copied to all namespaces that requires the registry authentication
# - If you run this module for the first time, you must ask a username/password to the registry administrator


# Check if the secret already exists
data "kubernetes_secret" "registry_auth" {
  metadata {
    name      = var.image_registry_auth_secret
    namespace = var.image_registry_auth_secret_source_namespace
  }
}


# Create the secret if it doesn't exist
resource "kubernetes_secret" "registry_auth" {
  count = data.kubernetes_secret.registry_auth == null ? 0 : 1

  metadata {
    name = var.image_registry_auth_secret
  }

  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        "${var.image_registry}" = {
          "username" = var.image_registry_username
          "password" = var.image_registry_password
          "auth"     = base64encode("${var.image_registry_username}:${var.image_registry_password}")
        }
      }
    })
  }

  type = "kubernetes.io/dockerconfigjson"

  lifecycle {
    precondition {
      condition     = var.image_registry_username != "" && var.image_registry_password != "" && var.image_registry_username != null && var.image_registry_password != null
      error_message = "EMPTY REGISTRY USERNAME OR PASSWORD.\nThe first time this module is running, you must provide a registry username/password (that will be stored in a secret and automatically reused the nexts times this module runs). Please ask the registry credentials to your administrator and fill the variables 'image_registry_username' and 'image_registry_password',\n\nCOPY/PASTE:\nexport TF_VAR_image_registry_username=USERNAME; export TF_VAR_image_registry_password=PASSWORD"
    }
  }
}
