resource "random_password" "harbor_postgres_password" {
  length  = 30
  special = false
}

resource "random_password" "harbor_postgres_admin_password" {
  length  = 30
  special = false
}

resource "random_password" "harbor_admin_password" {
  length  = 30
  special = false
}
# -----------------------------
# Kubernetes Secret for harbor Config
# -----------------------------
resource "kubernetes_secret" "harbor_config" {
  metadata {
    name      = "harbor-config"
    namespace = "harbor"
    labels = {
      "app" = "harbor"
    }
  }

  data = {
    harbor_admin_password          = var.harbor_admin_password != "" ? var.harbor_admin_password : random_password.harbor_admin_password.result
    harbor_postgres_user           = var.harbor_postgres_user
    harbor_postgres_password       = var.harbor_postgres_password != "" ? var.harbor_postgres_password : random_password.harbor_postgres_password.result
    harbor_postgres_admin_password = var.harbor_postgres_admin_password != "" ? var.harbor_postgres_admin_password : random_password.harbor_postgres_admin_password.result
  }

  type = "Opaque"
}
