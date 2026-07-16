# Create or update a container registry authentication
# - Such secrets are intended to be copied to all namespaces that require them
# - If you run this module for the first time, you may need to ask a credentials to the relevant registry administrators

locals {
  username = var.username == null ? jsondecode(data.kubernetes_secret.registry_auth[0].data[".dockerconfigjson"]).auths[var.registry].username : var.username
  password = var.password == null ? jsondecode(data.kubernetes_secret.registry_auth[0].data[".dockerconfigjson"]).auths[var.registry].password : var.password
}

# Check if the secret already exists
data "kubernetes_secret" "registry_auth" {
  count = (var.username == null || var.password == null) ? 1 : 0

  metadata {
    name      = var.secret
    namespace = var.namespace
  }

  lifecycle {
    postcondition {
      condition     = try(self.data[".dockerconfigjson"], null) != null
      error_message = <<-EOS
        Missing username and/or password for registry '${var.registry}'.
        The first time this module is running, you must provide the registry username/password.
        It will be stored in a secret and automatically reused on the next module runs.
        Please ask the registry credentials to your administrator.
      EOS
    }
  }
}

# Create/update the secret
resource "kubernetes_secret" "registry_auth" {
  metadata {
    name      = var.secret
    namespace = var.namespace
  }

  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        "${var.registry}" = {
          "username" = local.username
          "password" = local.password
          "auth"     = base64encode("${local.username}:${local.password}")
        }
      }
    })
  }

  type = "kubernetes.io/dockerconfigjson"

  lifecycle {
    prevent_destroy = true
  }
}
