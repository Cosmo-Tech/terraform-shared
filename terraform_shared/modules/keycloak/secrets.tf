# -----------------------------
# Random Passwords
# -----------------------------
resource "random_password" "keycloak_admin_password" {
  length  = 30
  special = false
}

resource "random_password" "keycloak_postgres_password" {
  length  = 30
  special = false
}

resource "random_password" "keycloak_postgres_admin_password" {
  length  = 30
  special = false
}

# -----------------------------
# Kubernetes Secret for Keycloak Config
# -----------------------------
resource "kubernetes_secret" "keycloak_config" {
  metadata {
    name      = var.keycloak_secret_name
    namespace = var.keycloak_namespace
    labels = {
      "app" = "keycloak"
    }
  }

  data = {
    keycloak_admin_user              = var.keycloak_admin_user
    keycloak_admin_password          = var.keycloak_admin_password != "" ? var.keycloak_admin_password : random_password.keycloak_admin_password.result
    keycloak_postgres_user           = var.keycloak_postgres_user
    keycloak_postgres_password       = var.keycloak_postgres_password != "" ? var.keycloak_postgres_password : random_password.keycloak_postgres_password.result
    keycloak_postgres_admin_password = var.keycloak_postgres_admin_password != "" ? var.keycloak_postgres_admin_password : random_password.keycloak_postgres_admin_password.result
  }

  type = "Opaque"
}
