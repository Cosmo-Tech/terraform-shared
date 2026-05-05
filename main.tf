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


module "kube_namespaces" {
  source = "./modules/kube_namespaces"

  namespaces = [
    "ingress-nginx",
    "cert-manager",
    "monitoring",
    "redis",
    "keycloak",
    "harbor",
    "superset"
  ]
}

# Timer to wait for storage to be created before continue
resource "time_sleep" "timer" {
  create_duration = "30s"
}

module "workload_scheduler" {
  source                    = "./modules/workload_scheduler"
  enable_workload_scheduler = local.enable_workload_scheduler
}

module "storageclass" {
  source                  = "./modules/kube_storageclass"
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

  dns_challenge_provider = var.dns_challenge_provider
  service_annotations    = local.cloud_identity
  cloud_provider         = var.cloud_provider
  cluster_domain         = local.cluster_domain
  certificate_email      = var.certificate_email

  depends_on = [
    module.kube_namespaces,
    module.chart_ingress_nginx,
  ]
}


module "chart_superset" {
  source = "./modules/chart_superset"

  namespace                = "superset"
  cluster_domain           = local.cluster_domain
  superset_cluster_domain  = "superset-${local.cluster_domain}"
  helm_repo                = "https://charts.bitnami.com/bitnami"
  helm_chart               = "superset"
  helm_chart_version       = "5.0.0"
  superset_connect_timeout = "30s"
  superset_query_timeout   = "60s"
  superset_buffer_size     = "16K"
  superset_max_file_size   = "5m"
  pvc_storage_class        = local.storage_class_name
  pvc_redis                = "pvc-${local.persistences.superset-redis["name"]}"
  pvc_postgresql           = "pvc-${local.persistences.superset-postgresql["name"]}"

  depends_on = [
    module.kube_namespaces,
    module.chart_ingress_nginx,
  ]
}


module "chart_harbor" {
  source = "./modules/chart_harbor"

  namespace = "harbor"

  cluster_domain = local.cluster_domain

  harbor_helm_repo          = "oci://registry-1.docker.io/bitnamicharts"
  harbor_helm_chart         = "harbor"
  harbor_helm_chart_version = "26.8.5"

  postgres_helm_repo          = "https://charts.bitnami.com/bitnami"
  postgres_helm_chart         = "postgresql"
  postgres_helm_chart_version = "15.5.1"

  redis_helm_repo          = "https://charts.bitnami.com/bitnami"
  redis_helm_chart         = "redis"
  redis_helm_chart_version = "17.3.14"

  pvc_storage_class = local.storage_class_name
  pvc_redis         = "pvc-${local.persistences.harbor-redis["name"]}"
  pvc_postgresql    = "pvc-${local.persistences.harbor-postgresql["name"]}"
  pvc_registry      = "pvc-${local.persistences.harbor-registry["name"]}"
  pvc_jobservice    = "pvc-${local.persistences.harbor-jobservice["name"]}"
  # pvc_chartmuseum   = "pvc-${local.persistences.harbor-chartmuseum["name"]}"
  # pvc_trivy         = "pvc-${local.persistences.harbor-trivy["name"]}"

  depends_on = [
    module.kube_namespaces,
    module.storageclass,
    module.chart_ingress_nginx,
  ]
}


module "chart_keycloak" {
  source = "./modules/chart_keycloak"

  namespace = "keycloak"

  keycloak_ingress_hostname = local.cluster_domain

  pvc_storage_class = local.storage_class_name
  pvc               = "pvc-${local.persistences.keycloak-postgresql["name"]}"

  keycloak_helm_repo          = "https://charts.bitnami.com/bitnami"
  keycloak_helm_chart         = "keycloak"
  keycloak_helm_chart_version = "21.3.1"

  postgres_helm_repo          = "https://charts.bitnami.com/bitnami"
  postgres_helm_chart         = "postgresql"
  postgres_helm_chart_version = "15.5.1"

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

  cluster_domain = local.cluster_domain

  helm_repo_url      = "https://prometheus-community.github.io/helm-charts"
  helm_release_name  = "kube-prometheus-stack"
  helm_chart_name    = "kube-prometheus-stack"
  helm_chart_version = "81.6.2"

  pvc_storage_class = local.storage_class_name
  # size              = 100
  # NOTE: kube-prometheus-stack 65.1.0 is not able to claim an existing PV, newers versions can handle it.
  size_prometheus = local.persistences.prometheusstack-prometheus["size"]
  pvc_prometheus  = "pvc-${local.persistences.prometheusstack-prometheus["name"]}"
  size_grafana    = local.persistences.prometheusstack-grafana["size"]
  pvc_grafana     = "pvc-${local.persistences.prometheusstack-grafana["name"]}"

  depends_on = [
    module.kube_namespaces,
    module.storageclass,
    module.chart_ingress_nginx,
  ]
}