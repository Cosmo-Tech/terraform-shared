locals {
  patcher_files = fileset("${path.module}/patcher", "*.yaml")
}

# Apply all 4 manifests in order
resource "kubectl_manifest" "pvc_patcher" {
  for_each = local.patcher_files

  yaml_body = templatefile("${path.module}/patcher/${each.value}", {
    namespace = var.tenant
  })

}