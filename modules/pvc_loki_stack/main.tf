locals {
  disk_grafana_name = "pvc-grafana"
  disk_loki_name    = "pvc-loki"
  pv_prefix         = "pv"
}

# Grafana PVC
resource "kubernetes_persistent_volume_claim" "grafana" {
  count = var.deploy_grafana_pvc ? 1 : 0

  metadata {
    name      = local.disk_grafana_name
    namespace = var.pvc_namespace
    labels = {
      "app.kubernetes.io/name"    = "grafana"
      "app.kubernetes.io/part-of" = "loki-stack"
    }
  }

  spec {
    access_modes       = [var.pvc_grafana_access_mode]
    storage_class_name = var.pvc_storage_class_name
    resources {
      requests = {
        storage = var.pvc_grafana_size
      }
    }
    volume_name = "${local.pv_prefix}-grafana"
  }
}

# Loki PVC
resource "kubernetes_persistent_volume_claim" "loki" {
  count = var.deploy_loki_pvc ? 1 : 0

  metadata {
    name      = local.disk_loki_name
    namespace = var.pvc_namespace
    labels = {
      "app.kubernetes.io/name"    = "loki"
      "app.kubernetes.io/part-of" = "loki-stack"
    }
  }

  spec {
    access_modes       = [var.pvc_loki_access_mode]
    storage_class_name = var.pvc_storage_class_name
    resources {
      requests = {
        storage = var.pvc_loki_size
      }
    }
    volume_name = "${local.pv_prefix}-loki"
  }
}
