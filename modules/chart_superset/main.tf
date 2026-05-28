locals {
  superset_secret_name                    = "superset"
  superset_redis_secret_name              = "superset-redis"
  superset_postgresql_secret_name         = "superset-postgresql"
  superset_guest_token_secret_name        = "superset-guest-token"
  superset_guest_token                    = random_password.superset_guest_token_secret.result
  superset_secret_key_name                = "superset-secret-key"
  superset_configmap_name                 = "superset-config"
  superset_oauth_providers_configmap_name = "superset-oauth-providers"

  chart_values_file = templatefile("${path.module}/values.yaml", local.chart_values)
  chart_values = {
    NAMESPACE                                        = var.namespace
    CLUSTER_DOMAIN                                   = var.cluster_domain
    SUPERSET_CLUSTER_DOMAIN                          = var.superset_cluster_domain
    SUPERSET_SECRET_NAME                             = local.superset_secret_name
    SUPERSET_REDIS_SECRET_NAME                       = local.superset_redis_secret_name
    SUPERSET_POSTGRESQL_SECRET_NAME                  = local.superset_postgresql_secret_name
    CONFIGMAP_NAME                                   = local.superset_configmap_name
    OAUTH_PROVIDERS_CONFIGMAP_NAME                   = local.superset_oauth_providers_configmap_name
    SUPERSET_GUEST_TOKEN                             = local.superset_guest_token
    SUPERSET_SECRET_KEY_NAME                         = local.superset_secret_key_name
    SUPERSET_CONNECT_TIMEOUT                         = var.superset_connect_timeout
    SUPERSET_QUERY_TIMEOUT                           = var.superset_query_timeout
    SUPERSET_BUFFER_SIZE                             = var.superset_buffer_size
    SUPERSET_MAX_FILE_SIZE                           = var.superset_max_file_size
    PERSISTENCE_STORAGE_CLASS                        = var.pvc_storage_class
    PERSISTENCE_REDIS_PVC                            = var.pvc_redis
    PERSISTENCE_POSTGRESQL_PVC                       = var.pvc_postgresql
    IMAGE_REGISTRY                                   = var.image_registry
    IMAGE_REGISTRY_AUTH_SECRET                       = var.image_registry_auth_secret
    POSTGRESQL_IMAGE_REPOSITORY                      = var.postgresql_image_repository
    POSTGRESQL_IMAGE_TAG                             = var.postgresql_image_tag
    PYTHON_REQUIREMENTS_INIT_CONTAINER               = indent(4, local.py_init_container)
    PYTHON_REQUIREMENTS_INIT_CONTAINER_VOLUMES       = indent(4, local.py_volumes)
    PYTHON_REQUIREMENTS_INIT_CONTAINER_VOLUME_MOUNTS = indent(4, local.py_volumes_mounts)
    PYTHON_REQUIREMENTS_EXTRA_ENV_VARS               = indent(6, local.py_env_vars)
  }

  py_main_name = "python-requirements"
  # py_venv_name = "superset-venv"
  # py_venv_path = "/usr/share/superset/venv"

  py_init_container = yamlencode([
    {
      name            = local.py_main_name
      image           = "python:3.11-slim"
      imagePullPolicy = "IfNotPresent"
      command         = ["sh", "-c", "pip install --target=/custom-pip --no-deps flask-cors Flask-OAuthlib authlib joserfc"]

      volumeMounts = [
        {
          name      = local.py_main_name
          mountPath = "/custom-pip"
        }
      ]
    }
  ])

  py_volumes = yamlencode([
    {
      name     = local.py_main_name
      emptyDir = {}
    }
  ])

  py_volumes_mounts = yamlencode([
    {
      name      = local.py_main_name
      mountPath = "/opt/custom-python-packages"
    }
  ])

  py_env_vars = yamlencode(
    {
      name  = "PYTHONPATH"
      value = "/opt/custom-python-packages"
    }
  )
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
    secret-key = random_password.superset_secret_key_value.result
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
    guest-token = local.superset_guest_token
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
    password            = random_password.superset_postgresql_password.result
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
resource "kubernetes_config_map" "superset_config_map" {
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
  namespace  = var.namespace
  name       = var.chart_release
  repository = var.chart_repository
  chart      = var.chart_name
  version    = var.chart_tag

  values = [
    local.chart_values_file
  ]

  force_update  = true
  recreate_pods = true

  lifecycle {
    replace_triggered_by = [
      terraform_data.helm_release_trigger,
    ]
  }

  depends_on = [
    kubernetes_config_map.superset_config_map
  ]
}

resource "terraform_data" "helm_release_trigger" {
  input = {
    version     = var.chart_tag
    values      = local.chart_values_file
    # values_sha1 = sha1(local.chart_values_file)
  }
}
## End of Superset Helm Chart
