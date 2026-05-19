# Authentication to Image Registry is required to allow usage of sub-images in Charts
# - This secret intends to be copied to all namespaces that requires the registry authentication
# - If you run this module for the first time, you must ask a username/password to the registry administrator


locals {
  image_registry_username = (var.image_registry_username == null ? jsondecode(data.kubernetes_secret.registry_auth[0].data[".dockerconfigjson"]).auths["${var.image_registry}"].username : var.image_registry_username)
  image_registry_password = (var.image_registry_password == null ? jsondecode(data.kubernetes_secret.registry_auth[0].data[".dockerconfigjson"]).auths["${var.image_registry}"].password : var.image_registry_password)
}


# Check if the secret already exists
data "kubernetes_secret" "registry_auth" {
  count = var.image_registry_username == null || var.image_registry_password == null ? 1 : 0

  metadata {
    name      = var.image_registry_auth_secret
    namespace = var.image_registry_auth_secret_source_namespace
  }


  # Just an human readable error
  lifecycle {
    postcondition {
      condition     = try(self.data[".dockerconfigjson"], "") != ""
      error_message = "EMPTY REGISTRY USERNAME OR PASSWORD.\nThe first time this module is running, you must provide a registry username/password (that will be stored in a secret and automatically reused the nexts times this module runs). Please ask the registry credentials to your administrator and fill the variables 'image_registry_username' and 'image_registry_password',\n\nCOPY/PASTE:\nexport TF_VAR_image_registry_username=USERNAME; export TF_VAR_image_registry_password=PASSWORD"
    }
  }
}

# Create the secret if it doesn't exist
resource "kubernetes_secret" "registry_auth" {
  metadata {
    name = var.image_registry_auth_secret
  }

  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        "${var.image_registry}" = {
          "username" = local.image_registry_username
          "password" = local.image_registry_password
          "auth"     = base64encode("${local.image_registry_username}:${local.image_registry_password}")
        }
      }
    })
  }

  type = "kubernetes.io/dockerconfigjson"

  lifecycle {
    prevent_destroy = true
  }
}
