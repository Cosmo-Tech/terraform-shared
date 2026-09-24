locals {
  cluster_domain     = "${var.cluster_name}.${var.domain_zone}"
  storage_class_name = "cosmotech-retain"
  persistences = {
    keycloak-postgresql = {
      namespace  = "keycloak"
      size       = 10
      main_name  = "${var.cluster_name}-keycloak-postgresql"
      pvc_name   = "keycloak-postgresql-1"
      create_pvc = false
    }
    prometheusstack-prometheus = {
      namespace  = "monitoring"
      size       = 100
      main_name  = "${var.cluster_name}-prometheusstack-prometheus"
      pvc_name   = "pvc-${var.cluster_name}-prometheusstack-prometheus"
      create_pvc = true
    }
    prometheusstack-grafana = {
      namespace  = "monitoring"
      size       = 10
      main_name  = "${var.cluster_name}-prometheusstack-grafana"
      pvc_name   = "pvc-${var.cluster_name}-prometheusstack-grafana"
      create_pvc = true
    }
    harbor-redis = {
      namespace  = "harbor"
      size       = 10
      main_name  = "${var.cluster_name}-harbor-redis"
      pvc_name   = "pvc-${var.cluster_name}-harbor-redis"
      create_pvc = true
    }
    harbor-postgresql = {
      namespace  = "harbor"
      size       = 10
      main_name  = "${var.cluster_name}-harbor-postgresql"
      pvc_name   = "harbor-postgresql-1"
      create_pvc = false
    }
    harbor-registry = {
      namespace  = "harbor"
      size       = 30
      main_name  = "${var.cluster_name}-harbor-registry"
      pvc_name   = "pvc-${var.cluster_name}-harbor-registry"
      create_pvc = true
    }
    harbor-jobservice = {
      namespace  = "harbor"
      size       = 10
      main_name  = "${var.cluster_name}-harbor-jobservice"
      pvc_name   = "pvc-${var.cluster_name}-harbor-jobservice"
      create_pvc = true
    }
    superset-postgresql = {
      namespace  = "superset"
      size       = 10
      main_name  = "${var.cluster_name}-superset-postgresql"
      pvc_name   = "superset-postgresql-1"
      create_pvc = false
    }
    superset-redis = {
      namespace  = "superset"
      size       = 10
      main_name  = "${var.cluster_name}-superset-redis"
      pvc_name   = "pvc-${var.cluster_name}-superset-redis"
      create_pvc = true
    }
  }
}


module "kube_namespaces" {
  source = "./modules/kube_namespaces"

  namespaces = [
    "traefik",
    "cert-manager",
    "cnpg-system",
    "monitoring",
    "keycloak",
    "harbor",
    "superset"
  ]
}


module "registry_authentication" {
  source = "./modules/registry_authentication"

  image_registry                              = var.image_registry
  image_registry_auth_secret_source_namespace = "default"
  image_registry_auth_secret                  = var.image_registry_auth_secret
  image_registry_username                     = var.image_registry_username
  image_registry_password                     = var.image_registry_password
  namespaces                                  = module.kube_namespaces.namespaces

  depends_on = [
    module.kube_namespaces,
  ]
}


# Timer to wait for storage to be created before continue.
# Also used a general gateway before install next modules.
resource "time_sleep" "timer" {
  create_duration = "30s"

  depends_on = [
    module.registry_authentication,
  ]
}


module "storageclass" {
  source = "./modules/kube_storageclass"

  cloud_provider          = var.cloud_provider
  storage_class           = local.storage_class_name
  deploy_storageclass     = true
  deploy_storageclass_nfs = true

  depends_on = [
    time_sleep.timer,
  ]
}


module "chart_traefik" {
  count = var.traefik_deploy == true ? 1 : 0

  source = "./modules/chart_traefik"

  namespace = "traefik"

  image_registry             = var.image_registry
  image_registry_auth_secret = var.image_registry_auth_secret
  image_repository_prefix    = var.image_repository_prefix

  chart_repository  = var.traefik_chart_repository
  chart_name        = var.traefik_chart_name
  chart_tag         = var.traefik_chart_tag
  chart_release     = "traefik"
  traefik_image_tag = var.traefik_image_tag

  lb_annotations = local.lb_annotations
  platform_lb_ip = local.lb_ip

  depends_on = [
    module.kube_namespaces,
    module.registry_authentication,
    time_sleep.timer,
  ]
}


module "chart_cert_manager" {
  count = var.cert_manager_deploy == true ? 1 : 0

  source = "./modules/chart_cert_manager"

  namespace = "cert-manager"

  image_registry             = var.image_registry
  image_registry_auth_secret = var.image_registry_auth_secret
  image_repository_prefix    = var.image_repository_prefix


  chart_repository       = var.cert_manager_chart_repository
  chart_name             = var.cert_manager_chart_name
  chart_tag              = var.cert_manager_chart_tag
  chart_release          = "cert-manager"
  cert_manager_image_tag = var.cert_manager_image_tag

  dns_challenge_provider = var.dns_challenge_provider
  # service_annotations    = local.cloud_identity
  # service_annotations    = tostring(local.cloud_identity)
  # service_annotations = replace(replace(jsonencode(local.cloud_identity), "\"", ""), ":", "=")
  service_annotations = yamlencode(local.cloud_identity)
  cloud_provider      = var.cloud_provider
  cluster_domain      = local.cluster_domain
  certificate_email   = var.certificate_email

  depends_on = [
    module.kube_namespaces,
    module.chart_traefik,
    time_sleep.timer,
  ]
}


module "chart_cnpg" {
  count = var.cnpg_deploy == true ? 1 : 0

  source = "./modules/chart_cnpg"

  namespace = "cnpg-system"

  image_registry             = var.image_registry
  image_registry_auth_secret = var.image_registry_auth_secret
  image_repository_prefix    = var.image_repository_prefix

  chart_cnpg_release    = var.cnpg_chart_name
  chart_cnpg_repository = var.cnpg_chart_repository
  chart_cnpg_name       = var.cnpg_chart_name
  chart_cnpg_tag        = var.cnpg_chart_tag
  cnpg_image_tag        = var.cnpg_image_tag

  depends_on = [
    module.kube_namespaces,
    time_sleep.timer,
  ]
}


module "chart_harbor" {
  count = var.harbor_deploy == true ? 1 : 0

  source = "./modules/chart_harbor"

  namespace = "harbor"

  image_registry             = var.image_registry
  image_registry_auth_secret = var.image_registry_auth_secret
  image_repository_prefix    = var.image_repository_prefix

  chart_harbor_repository = var.harbor_chart_repository
  chart_harbor_name       = var.harbor_chart_name
  chart_harbor_tag        = var.harbor_chart_tag
  chart_harbor_release    = "harbor"
  harbor_image_tag        = var.harbor_image_tag

  chart_redis_repository = var.harbor_redis_chart_repository
  chart_redis_name       = var.harbor_redis_chart_name
  chart_redis_tag        = var.harbor_redis_chart_tag
  chart_redis_release    = "harbor-redis"
  redis_image_tag        = var.harbor_redis_image_tag

  postgresql_image_name = var.postgresql_image_name
  postgresql_image_tag  = var.postgresql_image_tag

  generic_shell_image_name = var.generic_shell_image_name
  generic_shell_image_tag  = var.generic_shell_image_tag

  pvc_storage_class = local.storage_class_name
  pvc_redis         = local.persistences.harbor-redis["pvc_name"]
  pvc_postgresql    = local.persistences.harbor-postgresql["pvc_name"]
  pvc_registry      = local.persistences.harbor-registry["pvc_name"]
  pvc_jobservice    = local.persistences.harbor-jobservice["pvc_name"]
  persistence_size  = local.persistences.harbor-postgresql["size"]

  cluster_domain = local.cluster_domain

  depends_on = [
    module.kube_namespaces,
    module.storageclass,
    module.chart_traefik,
    module.chart_cert_manager,
    module.chart_cnpg,
    time_sleep.timer,
  ]
}


module "chart_keycloak" {
  count = var.keycloak_deploy == true ? 1 : 0

  source = "./modules/chart_keycloak"

  namespace = "keycloak"

  image_registry             = var.image_registry
  image_registry_auth_secret = var.image_registry_auth_secret
  image_repository_prefix    = var.image_repository_prefix

  chart_keycloak_repository = var.keycloak_chart_repository
  chart_keycloak_name       = var.keycloak_chart_name
  chart_keycloak_tag        = var.keycloak_chart_tag
  chart_keycloak_release    = "keycloak"
  keycloak_image_tag        = var.keycloak_image_tag

  postgresql_image_name = var.postgresql_image_name
  postgresql_image_tag  = var.postgresql_image_tag

  pvc_storage_class = local.storage_class_name
  pvc               = local.persistences.keycloak-postgresql["pvc_name"]
  persistence_size  = local.persistences.keycloak-postgresql["size"]

  keycloak_ingress_hostname = local.cluster_domain

  depends_on = [
    module.kube_namespaces,
    module.storageclass,
    module.chart_traefik,
    module.chart_cert_manager,
    module.chart_cnpg,
    time_sleep.timer,
  ]
}


module "chart_prometheus_stack" {
  count = var.prometheusstack_deploy == true ? 1 : 0

  source = "./modules/chart_prometheus_stack"

  namespace = "monitoring"

  image_registry             = var.image_registry
  image_registry_auth_secret = var.image_registry_auth_secret
  image_repository_prefix    = var.image_repository_prefix

  chart_repository = var.prometheusstack_chart_repository
  chart_name       = var.prometheusstack_chart_name
  chart_tag        = var.prometheusstack_chart_tag
  chart_release    = "kube-prometheus-stack"

  generic_shell_image_name = var.generic_shell_image_name
  generic_shell_image_tag  = var.generic_shell_image_tag

  pvc_storage_class = local.storage_class_name
  size_prometheus   = local.persistences.prometheusstack-prometheus["size"]
  pvc_prometheus    = local.persistences.prometheusstack-prometheus["pvc_name"]
  size_grafana      = local.persistences.prometheusstack-grafana["size"]
  pvc_grafana       = local.persistences.prometheusstack-grafana["pvc_name"]

  cluster_domain = local.cluster_domain

  depends_on = [
    module.kube_namespaces,
    module.storageclass,
    module.chart_traefik,
    module.chart_cert_manager,
    time_sleep.timer,
  ]
}


module "chart_superset" {
  count = var.superset_deploy == true ? 1 : 0

  source = "./modules/chart_superset"

  namespace = "superset"

  image_registry             = var.image_registry
  image_registry_auth_secret = var.image_registry_auth_secret
  image_repository_prefix    = var.image_repository_prefix

  chart_repository = var.superset_chart_repository
  chart_name       = var.superset_chart_name
  chart_tag        = var.superset_chart_tag
  chart_release    = "superset"

  superset_image_tag = var.superset_image_tag

  redis_image_tag = var.superset_redis_image_tag

  postgresql_image_name = var.postgresql_image_name
  postgresql_image_tag  = var.postgresql_image_tag

  pvc_storage_class = local.storage_class_name
  pvc_redis         = local.persistences.superset-redis["pvc_name"]
  pvc_postgresql    = local.persistences.superset-postgresql["pvc_name"]
  persistence_size  = local.persistences.superset-postgresql["size"]

  cluster_domain          = local.cluster_domain
  superset_cluster_domain = "superset-${local.cluster_domain}"

  superset_connect_timeout = "30s"
  superset_query_timeout   = "60s"
  superset_buffer_size     = "16K"
  superset_max_file_size   = "5m"

  depends_on = [
    module.kube_namespaces,
    module.chart_traefik,
    module.chart_cert_manager,
    module.chart_cnpg,
    time_sleep.timer,
  ]
}


module "workload_scheduler" {
  # Do not deploy for on-premise, or if false
  count = var.cloud_provider == "kob" ? 0 : (var.workload_scheduler_deploy == true ? 1 : 0)
  # count = var.cloud_provider == "kob" ? false : var.workload_scheduler_deploy

  source = "./modules/workload_scheduler"

  scaler_time_zone         = var.workload_scheduler_timezone
  scale_down_cron_schedule = var.workload_scheduler_cron_stop
  scale_up_cron_schedule   = var.workload_scheduler_cron_start

  depends_on = [
    time_sleep.timer,
  ]
}