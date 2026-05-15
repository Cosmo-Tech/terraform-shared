# Authentication to Image Registry is required to allow usage of sub-images in Charts
# - This secret intends to be copied to all namespaces that requires the registry authentication
# - You must ask a username/password to the registry administrator to use this module


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
}