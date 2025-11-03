# -----------------------------
# Local values for Helm charts
# -----------------------------
locals {
  keycloak_values = {
    NAMESPACE                          = var.keycloak_namespace
    SECRET                             = var.keycloak_secret_name
    ADMIN_USER                         = var.keycloak_admin_user
    ADMIN_PASSWORD_SECRET_KEY          = "keycloak_admin_password"
    INGRESS_HOSTNAME                   = var.keycloak_ingress_hostname
    POSTGRES_USER                      = var.keycloak_postgres_user
    POSTGRES_PASSWORD_SECRET_KEY       = "keycloak_postgres_password"
    POSTGRES_ADMIN_PASSWORD_SECRET_KEY = "keycloak_postgres_admin_password"
    STORAGE_CLASS                      = var.postgres_storage_class_name
    PVC_NAME                           = var.pvc_postgres_keycloak_name
    POSTGRES_TAG                       = ""
  }
}

# -----------------------------
# PostgreSQL Helm Release
# -----------------------------
resource "helm_release" "postgresql" {
  name       = "keycloak-postgresql"
  repository = var.postgres_helm_repo
  chart      = var.postgres_helm_chart
  version    = var.postgres_helm_chart_version
  namespace  = var.keycloak_namespace

  values = [
    templatefile("${path.root}/helm-templates/keycloak/values-postgresql.yaml", local.keycloak_values)
  ]
}

# -----------------------------
# Keycloak Helm Release
# -----------------------------
resource "helm_release" "keycloak" {
  name       = "keycloak"
  repository = var.keycloak_helm_repo
  chart      = var.keycloak_helm_chart
  version    = var.keycloak_helm_chart_version
  namespace  = var.keycloak_namespace

  values = [
    templatefile("${path.root}/helm-templates/keycloak/values-keycloak.yaml", local.keycloak_values)
  ]

  depends_on = [helm_release.postgresql]
}
