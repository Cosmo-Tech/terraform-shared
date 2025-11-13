locals {
  harbor_pvs = {
    "registry"    = { disk_size_gb = 50, storage_class_name = "cosmotech-retain", access_modes = ["ReadWriteOnce"] }
    "jobservice"  = { disk_size_gb = 50, storage_class_name = "cosmotech-retain", access_modes = ["ReadWriteOnce"] }
    "chartmuseum" = { disk_size_gb = 50, storage_class_name = "cosmotech-retain", access_modes = ["ReadWriteOnce"] }
    "trivy"       = { disk_size_gb = 50, storage_class_name = "cosmotech-retain", access_modes = ["ReadWriteOnce"] }
    "postgresql"  = { disk_size_gb = 50, storage_class_name = "cosmotech-retain", access_modes = ["ReadWriteOnce"] }
    "redis"       = { disk_size_gb = 50, storage_class_name = "cosmotech-retain", access_modes = ["ReadWriteOnce"] }
  }
}

resource "kubernetes_persistent_volume_claim" "harbor" {
  for_each = var.deploy_harbor_pvc ? local.harbor_pvs : {}

  metadata {
    name      = "pvc-harbor-${each.key}"
    namespace = var.harbor_namespace
    labels = {
      "app.kubernetes.io/name" = "harbor"
    }
  }

  spec {
    access_modes       = each.value.access_modes
    storage_class_name = each.value.storage_class_name
    resources {
      requests = {
        storage = "${each.value.disk_size_gb}Gi"
      }
    }
    volume_name = "pv-harbor-${each.key}"
  }
}
