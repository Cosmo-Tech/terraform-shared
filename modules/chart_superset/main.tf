locals {
  superset_secret_name    = "superset"
  superset_redis_secret_name    = "superset-redis"
  superset_postgresql_secret_name    = "superset-postgresql"
  superset_guest_token_secret_name    = "superset-guest-token"
  superset_guest_token    = random_password.superset_guest_token_secret.result
  superset_secret_key_name    = "superset-secret-key"
  superset_configmap_name = "superset-config"
  superset_oauth_providers_configmap_name = "superset-oauth-providers"

  chart_values = {
    NAMESPACE      = var.namespace
    CLUSTER_DOMAIN = var.cluster_domain
    SUPERSET_CLUSTER_DOMAIN = var.superset_cluster_domain
    SUPERSET_SECRET_NAME    = local.superset_secret_name
    SUPERSET_REDIS_SECRET_NAME    = local.superset_redis_secret_name
    SUPERSET_POSTGRESQL_SECRET_NAME    = local.superset_postgresql_secret_name
    CONFIGMAP_NAME = local.superset_configmap_name
    OAUTH_PROVIDERS_CONFIGMAP_NAME = local.superset_oauth_providers_configmap_name
    SUPERSET_GUEST_TOKEN = local.superset_guest_token
    SUPERSET_SECRET_KEY_NAME = local.superset_secret_key_name
  }
}


## Secret Key for signing the session cookie (Flask App Builder configuration)
resource "random_password" "superset_secret_key_value" {
  length  = 40
  special = false
}

resource "kubernetes_secret" "superset_secret_key_secret" {
  metadata {
    name      = local.superset_secret_key_name
    namespace = var.namespace
  }

  data = {
    secret-key   = random_password.superset_secret_key_value.result
  }

  type = "Opaque"
}

## End of  Secret Key for signing the session cookie (Flask App Builder configuration

## Guest token for dashboard embedding
resource "random_password" "superset_guest_token_secret" {
  length  = 40
  special = false
}

resource "kubernetes_secret" "superset_guest_token" {
  metadata {
    name      = local.superset_guest_token_secret_name
    namespace = var.namespace
  }

  data = {
    guest-token   = local.superset_guest_token
  }

  type = "Opaque"
}

## End of Guest token

## Superset, Postgresql, Redis secrets

## Superset
 resource "random_password" "superset_password" {
   length  = 40
   special = false
 }

resource "random_password" "superset_secret_key" {
  length  = 40
  special = false
}

 resource "kubernetes_secret" "superset_secret" {
   metadata {
     name      = local.superset_secret_name
     namespace = var.namespace
   }

   data = {
     superset-password   = random_password.superset_password.result
     superset-secret-key = random_password.superset_secret_key.result
   }

   type = "Opaque"
 }
## End of Superset

## Superset <-> Postgresql
resource "random_password" "superset_postgresql_password" {
  length  = 40
  special = false
}

resource "random_password" "superset_user_postgresql_password" {
  length  = 40
  special = false
}

resource "kubernetes_secret" "superset_postgresql" {
  metadata {
    name      = local.superset_postgresql_secret_name
    namespace = var.namespace
  }

  data = {
    password   = random_password.superset_postgresql_password.result
    postgresql-password = random_password.superset_user_postgresql_password.result
  }

  type = "Opaque"
}
## End of Superset <-> Postgresql

## Superset <-> Redis
resource "random_password" "superset_redis_password" {
  length  = 40
  special = false
}

resource "kubernetes_secret" "superset_redis" {
  metadata {
    name      = local.superset_redis_secret_name
    namespace = var.namespace
  }

  data = {
    redis-password = random_password.superset_redis_password.result
  }

  type = "Opaque"
}
## End of Superset <-> Redis
## End of Superset, Postgresql, Redis secrets

## ConfigMap with superset_config.py
resource "kubernetes_config_map" "superset_config_map"{
  metadata {
    name      = local.superset_configmap_name
    namespace = var.namespace
  }

  data = {
    "superset_config.py" = templatefile("${path.module}/kube_objects/superset_config.py", local.chart_values)
  }
}
## End of ConfigMap with superset_config.py

## Superset Helm Chart
resource "helm_release" "superset" {
  name       = "superset"
  repository = var.helm_repo
  chart      = var.helm_chart
  version    = var.helm_chart_version
  namespace  = var.namespace

  values = [
    templatefile("${path.module}/values.yaml", local.chart_values)
  ]

  depends_on = [
    kubernetes_config_map.superset_config_map
  ]
}
## End of Superset Helm Chart
