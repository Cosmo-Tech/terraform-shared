locals {
  cluster_domain            = "${var.cluster_name}.${var.domain_zone}"
  storage_class_name        = "cosmotech-retain"
  enable_workload_scheduler = true
  persistences = {
    keycloak-postgresql = {
      size      = 10
      name      = "${var.cluster_name}-keycloak-postgresql"
      namespace = "keycloak"
    }
    # lokistack-loki = {
    #   size      = 50
    #   name      = "${var.cluster_name}-lokistack-loki"
    #   namespace = "monitoring"
    # }
    prometheusstack-prometheus = {
      size      = 100
      name      = "${var.cluster_name}-prometheusstack-prometheus"
      namespace = "monitoring"
    }
    prometheusstack-grafana = {
      size      = 10
      name      = "${var.cluster_name}-prometheusstack-grafana"
      namespace = "monitoring"
    }
    harbor-redis = {
      size      = 10
      name      = "${var.cluster_name}-harbor-redis"
      namespace = "harbor"
    }
    harbor-postgresql = {
      size      = 10
      name      = "${var.cluster_name}-harbor-postgresql"
      namespace = "harbor"
    }
    harbor-registry = {
      size      = 30
      name      = "${var.cluster_name}-harbor-registry"
      namespace = "harbor"
    }
    harbor-jobservice = {
      size      = 10
      name      = "${var.cluster_name}-harbor-jobservice"
      namespace = "harbor"
    }
    # harbor-chartmuseum = {
    #   size      = 10
    #   name      = "${var.cluster_name}-harbor-chartmuseum"
    #   namespace = "harbor"
    # }
    # harbor-trivy = {
    #   size      = 10
    #   name      = "${var.cluster_name}-harbor-trivy"
    #   namespace = "harbor"
    # }
    superset-postgresql = {
      size      = 10
      name      = "${var.cluster_name}-superset-postgresql"
      namespace = "superset"
    }
    superset-redis = {
      size      = 10
      name      = "${var.cluster_name}-superset-redis"
      namespace = "superset"
    }
  }
}


module "registry_authentication" {
  source = "./modules/registry_authentication"

  image_registry_auth_secret_source_namespace = var.image_registry_auth_secret_source_namespace
  image_registry                              = var.image_registry
  image_registry_auth_secret                  = var.image_registry_auth_secret
  image_registry_username                     = var.image_registry_username
  image_registry_password                     = var.image_registry_password
}


module "kube_namespaces" {
  source = "./modules/kube_namespaces"

  namespaces = [
    "ingress-nginx",
    "cert-manager",
    "monitoring",
    "keycloak",
    "harbor",
    "superset"
  ]

  image_registry_auth_secret_source_namespace = var.image_registry_auth_secret_source_namespace
  image_registry                              = var.image_registry
  image_registry_auth_secret                  = var.image_registry_auth_secret

  depends_on = [
    module.registry_authentication,
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


module "workload_scheduler" {
  source = "./modules/workload_scheduler"

  enable_workload_scheduler = local.enable_workload_scheduler

  depends_on = [
    time_sleep.timer,
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


module "chart_ingress_nginx" {
  source = "./modules/chart_ingress_nginx"

  platform_lb_ip      = local.lb_ip
  service_annotations = local.cloud_identity
  lb_annotations      = local.lb_annotations

  depends_on = [
    module.kube_namespaces,
    time_sleep.timer,
  ]
}


module "chart_cert_manager" {
  source = "./modules/chart_cert_manager"

  namespace = "cert-manager"

  image_registry             = var.image_registry
  image_registry_auth_secret = var.image_registry_auth_secret

  chart_repository = var.certmanager_chart_repository
  chart_name       = var.certmanager_chart_name
  chart_tag        = var.certmanager_chart_tag
  chart_release    = "cert-manager"

  dns_challenge_provider = var.dns_challenge_provider
  # service_annotations    = tostring(local.cloud_identity)
  service_annotations = replace(replace(jsonencode(local.cloud_identity), "\"", ""), ":", "=")
  cloud_provider      = var.cloud_provider
  cluster_domain      = local.cluster_domain
  certificate_email   = var.certificate_email

  depends_on = [
    module.kube_namespaces,
    module.chart_ingress_nginx,
  ]
}


module "chart_harbor" {
  source = "./modules/chart_harbor"

  namespace = "harbor"

  image_registry             = var.image_registry
  image_registry_auth_secret = var.image_registry_auth_secret

  chart_harbor_repository = var.harbor_chart_repository
  chart_harbor_name       = var.harbor_chart_name
  chart_harbor_tag        = var.harbor_chart_tag
  chart_harbor_release    = "harbor"

  chart_postgresql_repository = var.harbor_postgresql_chart_repository
  chart_postgresql_name       = var.harbor_postgresql_chart_name
  chart_postgresql_tag        = var.harbor_postgresql_chart_tag
  chart_postgresql_release    = "harbor-postgresql"

  chart_redis_repository = var.harbor_redis_chart_repository
  chart_redis_name       = var.harbor_redis_chart_name
  chart_redis_tag        = var.harbor_redis_chart_tag
  chart_redis_release    = "harbor-redis"

  pvc_storage_class = local.storage_class_name
  pvc_redis         = "pvc-${local.persistences.harbor-redis["name"]}"
  pvc_postgresql    = "pvc-${local.persistences.harbor-postgresql["name"]}"
  pvc_registry      = "pvc-${local.persistences.harbor-registry["name"]}"
  pvc_jobservice    = "pvc-${local.persistences.harbor-jobservice["name"]}"

  cluster_domain = local.cluster_domain

  depends_on = [
    module.kube_namespaces,
    module.storageclass,
    module.chart_ingress_nginx,
  ]
}


module "chart_keycloak" {
  source = "./modules/chart_keycloak"

  namespace = "keycloak"

  image_registry             = var.image_registry
  image_registry_auth_secret = var.image_registry_auth_secret

  chart_keycloak_repository = var.keycloak_chart_repository
  chart_keycloak_name       = var.keycloak_chart_name
  chart_keycloak_tag        = var.keycloak_chart_tag
  chart_keycloak_release    = "keycloak"

  chart_postgresql_repository = var.keycloak_postgresql_chart_repository
  chart_postgresql_name       = var.keycloak_postgresql_chart_name
  chart_postgresql_tag        = var.keycloak_postgresql_chart_tag
  chart_postgresql_release    = "keycloak-postgresql"

  pvc_storage_class = local.storage_class_name
  pvc               = "pvc-${local.persistences.keycloak-postgresql["name"]}"

  keycloak_ingress_hostname = local.cluster_domain

  depends_on = [
    module.kube_namespaces,
    module.storageclass,
    module.chart_ingress_nginx,
  ]
}


# module "chart_loki_stack" {
#   source = "./modules/chart_loki_stack"

#   namespace = "monitoring"

#   helm_repo_url      = "https://grafana.github.io/helm-charts"
#   helm_chart_name    = "loki-stack"
#   helm_chart_version = "2.10.2"
#   helm_release_name  = "loki"

#   # pvc_storage_class = local.storage_class_name
#   # pvc_loki          = "pvc-${local.persistences.lokistack-loki["name"]}"
#   # size_loki         = local.persistences.lokistack-loki["size"]
#   # pvc_grafana       = "pvc-${local.persistences.lokistack-grafana["name"]}"
#   # size_grafana      = local.persistences.lokistack-grafana["size"]

#   depends_on = [
#     module.kube_namespaces,
#     module.storageclass,
#     module.chart_ingress_nginx,
#   ]
# }


module "chart_prometheus_stack" {
  source = "./modules/chart_prometheus_stack"

  namespace = "monitoring"

  image_registry             = var.image_registry
  image_registry_auth_secret = var.image_registry_auth_secret

  chart_repository = var.prometheusstack_chart_repository
  chart_name       = var.prometheusstack_chart_name
  chart_tag        = var.prometheusstack_chart_tag
  chart_release    = "kube-prometheus-stack"

  pvc_storage_class = local.storage_class_name
  size_prometheus   = local.persistences.prometheusstack-prometheus["size"]
  pvc_prometheus    = "pvc-${local.persistences.prometheusstack-prometheus["name"]}"
  size_grafana      = local.persistences.prometheusstack-grafana["size"]
  pvc_grafana       = "pvc-${local.persistences.prometheusstack-grafana["name"]}"

  cluster_domain = local.cluster_domain

  depends_on = [
    module.kube_namespaces,
    module.storageclass,
    module.chart_ingress_nginx,
  ]
}


module "chart_superset" {
  source = "./modules/chart_superset"

  namespace = "superset"

  image_registry             = var.image_registry
  image_registry_auth_secret = var.image_registry_auth_secret

  chart_repository = var.superset_chart_repository
  chart_name       = var.superset_chart_name
  chart_tag        = var.superset_chart_tag
  chart_release    = "superset"

  pvc_storage_class = local.storage_class_name
  pvc_redis         = "pvc-${local.persistences.superset-redis["name"]}"
  pvc_postgresql    = "pvc-${local.persistences.superset-postgresql["name"]}"

  cluster_domain          = local.cluster_domain
  superset_cluster_domain = "superset-${local.cluster_domain}"

  superset_connect_timeout = "30s"
  superset_query_timeout   = "60s"
  superset_buffer_size     = "16K"
  superset_max_file_size   = "5m"

  depends_on = [
    module.kube_namespaces,
    module.chart_ingress_nginx,
  ]
}
