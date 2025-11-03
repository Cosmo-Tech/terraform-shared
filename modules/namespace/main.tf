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


