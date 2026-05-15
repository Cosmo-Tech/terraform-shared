locals {
  keycloak_secret_name_config             = "keycloak-config"
  keycloak_secret_name_crt                = "keycloak-crt"
  keycloak_admin_user                     = "admin"
  keycloak_admin_password_secret          = "keycloak_admin_password"
  keycloak_postgres_user                  = "keycloak"
  keycloak_postgres_user_password_secret  = "keycloak_postgres_password"
  keycloak_postgres_admin_password_secret = "keycloak_postgres_admin_password"

  chart_values = {
    NAMESPACE                          = var.namespace
    INGRESS_HOSTNAME                   = var.keycloak_ingress_hostname
    PERSISTENCE_STORAGE_CLASS          = var.pvc_storage_class
    PERSISTENCE_PVC                    = var.pvc
    KEYCLOAK_SECRET                    = local.keycloak_secret_name_config
    KEYCLOAK_ADMIN_USER                = local.keycloak_admin_user
    KEYCLOAK_ADMIN_PASSWORD_SECRET_KEY = local.keycloak_admin_password_secret
    POSTGRES_USER                      = local.keycloak_postgres_user
    POSTGRES_PASSWORD_SECRET_KEY       = local.keycloak_postgres_user_password_secret
    POSTGRES_ADMIN_PASSWORD_SECRET_KEY = local.keycloak_postgres_admin_password_secret
    IMAGE_REGISTRY                     = var.image_registry
    IMAGE_REGISTRY_AUTH_SECRET         = var.image_registry_auth_secret
    POSTGRESQL_IMAGE_REPOSITORY        = var.postgresql_image_repository
    POSTGRESQL_IMAGE_TAG               = var.postgresql_image_tag
  }
}


resource "random_password" "keycloak_admin_password" {
  length  = 40
  special = false
}

resource "random_password" "keycloak_postgres_password" {
  length  = 40
  special = false
}

resource "random_password" "keycloak_postgres_admin_password" {
  length  = 40
  special = false
}


resource "kubernetes_secret" "keycloak_config" {
  metadata {
    name      = local.keycloak_secret_name_config
    namespace = var.namespace
    labels = {
      "app" = "keycloak"
    }
  }

  data = {
    keycloak_admin_user              = local.keycloak_admin_user
    keycloak_admin_password          = var.keycloak_admin_password != "" ? var.keycloak_admin_password : random_password.keycloak_admin_password.result
    keycloak_postgres_user           = local.keycloak_postgres_user
    keycloak_postgres_password       = var.keycloak_postgres_password != "" ? var.keycloak_postgres_password : random_password.keycloak_postgres_password.result
    keycloak_postgres_admin_password = var.keycloak_postgres_admin_password != "" ? var.keycloak_postgres_admin_password : random_password.keycloak_postgres_admin_password.result
  }

  type = "Opaque"
}


resource "helm_release" "postgresql" {
  namespace  = var.namespace
  name       = var.chart_postgresql_release
  repository = var.chart_postgresql_repository
  chart      = var.chart_postgresql_name
  version    = var.chart_postgresql_tag

  values = [
    templatefile("${path.module}/values-postgresql.yaml", local.chart_values)
  ]
}


resource "helm_release" "keycloak" {
  namespace  = var.namespace
  name       = var.chart_keycloak_release
  repository = var.chart_keycloak_repository
  chart      = var.chart_keycloak_name
  version    = var.chart_keycloak_tag

  values = [
    templatefile("${path.module}/values-keycloak.yaml", local.chart_values)
  ]

  depends_on = [
    helm_release.postgresql
  ]
}
