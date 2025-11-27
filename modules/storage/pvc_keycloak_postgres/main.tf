locals {
  disk_name = "pvc-keycloak"
  pv_prefix = "pv"
}

resource "kubernetes_persistent_volume_claim" "postgres_keycloak" {
  count = var.deploy_postgres_pvc ? 1 : 0

  metadata {
    name      = local.disk_name
    namespace = var.keycloak_namespace
    labels = {
      "app.kubernetes.io/name"    = "keycloak-postgres"
      "app.kubernetes.io/part-of" = "keycloak"
    }
  }

  spec {
    access_modes       = [var.pvc_postgres_access_mode]
    storage_class_name = var.pvc_postgres_storage_class_name
    resources {
      requests = {
        storage = var.pvc_postgres_size
      }
    }
    volume_name = "${local.pv_prefix}-keycloak"
  }
}
