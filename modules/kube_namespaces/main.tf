resource "kubernetes_namespace" "this" {
  for_each = toset(var.namespaces)

  metadata {
    name   = each.key
    labels = var.labels
  }

  lifecycle {
    prevent_destroy = false
  }
}

# Copy the registry auth secret
data "kubernetes_secret" "registry_auth" {
  metadata {
    name      = var.image_registry_auth_secret
    namespace = var.image_registry_auth_secret_source_namespace
  }
}

# Paste the registry auth secret in all namespaces
resource "kubernetes_secret" "registry_auth" {
  for_each = toset(var.namespaces)

  metadata {
    name      = data.kubernetes_secret.registry_auth.metadata[0].name
    namespace = each.key
  }

  data = {
    ".dockerconfigjson" = data.kubernetes_secret.registry_auth.data[".dockerconfigjson"]
  }

  type = "kubernetes.io/dockerconfigjson"
}