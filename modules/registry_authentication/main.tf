## Authentication to image registries is required to allow Kubernetes pulling images
## - These secrets intends to be copied to all namespaces that requires the registries authentication
## - If you run this module for the first time, you must ask at least one username/password to the registry administrator


locals {
  # Format target secret name for each registry in var.image_registries
  # "example.com" -> "registry-auth-example-com"
  target_registries = {
    for key, reg in var.image_registries :
    "registry-auth-${replace(replace(replace(reg.server, "https://", ""), "http://", ""), "/[.:/]/", "-")}" => reg
  }
}

# 1. Read existing secret from cluster if username or password is not provided in var.image_registries
data "kubernetes_secret" "existing_registry_auth" {
  for_each = {
    for secret, registry in local.target_registries :
    secret => registry
    if registry.username == null || registry.password == null
  }

  metadata {
    name      = each.key
    namespace = var.image_registry_auth_secret_source_namespace
  }

  # Human-readable error message if credentials are missing and secret does not exist yet
  lifecycle {
    postcondition {
      condition     = try(self.data[".dockerconfigjson"], "") != ""
      error_message = <<EOT
MISSING REGISTRY CREDENTIALS for '${each.value.server}'. The secret '${each.key}' does not exist on the cluster yet.

On the first run, you must provide the registry username and password:

export TF_VAR_image_registries='{
  "${each.key}": {
    "server": "${each.value.server}",
    "username": "USERNAME",
    "password": "PASSWORD"
  }
}'
EOT
    }
  }
}


locals {
  # 2. Resolve final credentials (Variable priority -> Fallback to existing cluster secret)
  final_registries = {
    for secret, registry in local.target_registries : secret => {
      server = registry.server

      username = (
        registry.username != null ? registry.username :
        jsondecode(data.kubernetes_secret.existing_registry_auth[secret].data[".dockerconfigjson"]).auths[registry.server].username
      )

      password = (
        registry.password != null ? registry.password :
        jsondecode(data.kubernetes_secret.existing_registry_auth[secret].data[".dockerconfigjson"]).auths[registry.server].password
      )
    }
  }

  # 3. Build a static matrix for target namespaces duplication (Target Namespaces x Registries)
  secret_copies = flatten([
    for ns in var.namespaces : [
      for secret, registry in local.final_registries : {
        id        = "${ns}/${secret}"
        namespace = ns
        secret    = secret
        server    = registry.server
        username  = registry.username
        password  = registry.password
      }
    ]
  ])
}

# 3. Create or update dockerconfigjson secrets in source namespace
resource "kubernetes_secret" "registry_auth" {
  for_each = local.final_registries

  metadata {
    name      = each.key
    namespace = var.image_registry_auth_secret_source_namespace
  }

  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        "${each.value.server}" = {
          "username" = each.value.username
          "password" = each.value.password
          "auth"     = base64encode("${each.value.username}:${each.value.password}")
        }
      }
    })
  }

  type = "kubernetes.io/dockerconfigjson"

  lifecycle {
    prevent_destroy = true
    ignore_changes = [
      metadata,
    ]
  }
}

# 4. Duplicate dockerconfigjson secrets into created namespaces
resource "kubernetes_secret" "registry_auth_copies" {
  for_each = { for item in local.secret_copies : item.id => item }

  metadata {
    name      = each.value.secret
    namespace = each.value.namespace
  }

  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        "${each.value.server}" = {
          "username" = each.value.username
          "password" = each.value.password
          "auth"     = base64encode("${each.value.username}:${each.value.password}")
        }
      }
    })
  }

  type = "kubernetes.io/dockerconfigjson"
}