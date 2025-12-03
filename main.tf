module "kube_namespaces" {
  source = "./modules/kube_namespaces"

  namespaces = [
    "ingress-nginx",
    "cert-manager",
    "monitoring",
    "redis",
    "keycloak",
    "harbor"
  ]

  # labels = {
  #   "environment" = "shared"
  #   "team"        = "devops"
  # }
}


module "chart_ingress_nginx" {
  source = "./modules/chart_ingress_nginx"

  platform_lb_ip = local.lb_ip
  # cluster_endpoint       = data.terraform_remote_state.terraform_cluster.outputs.cluster_endpoint
  # cluster_ca_certificate = data.terraform_remote_state.terraform_cluster.outputs.cluster_ca_certificate
  service_annotations = local.cloud_identity
  lb_annotations      = local.lb_annotations

  depends_on = [
    module.kube_namespaces
  ]
}


module "chart_cert_manager" {
  source = "./modules/chart_cert_manager"

  service_annotations = local.cloud_identity
  certificate_email   = var.certificate_email
  # cluster_endpoint       = data.terraform_remote_state.terraform_cluster.outputs.cluster_endpoint
  # cluster_ca_certificate = data.terraform_remote_state.terraform_cluster.outputs.cluster_ca_certificate
  cluster_domain = local.cluster_domain

  depends_on = [
    module.kube_namespaces
  ]
}


module "chart_prometheus_stack" {
  source = "./modules/chart_prometheus_stack"

  project_name            = "cosmotech"
  namespace               = "monitoring"
  cluster_domain          = local.cluster_domain
  tls_secret_name         = "letsencrypt-prod"
  redis_host_namespace    = "redis"
  prom_storage_class_name = "cosmotech-retain"
  helm_chart_version      = "65.1.0"

  depends_on = [
    module.kube_namespaces,
    module.storageclass,
  ]
}


module "storageclass" {
  source = "./modules/storage/storageclass"

  cloud_provider          = var.cloud_provider
  deploy_storageclass     = true
  deploy_storageclass_nfs = true
}


module "pvc_loki_stack" {
  source        = "./modules/storage/pvc_loki_stack"
  pvc_namespace = "monitoring"

  deploy_grafana_pvc = true
  deploy_loki_pvc    = true

  pvc_storage_class_name = "cosmotech-retain"
  pvc_grafana_size       = "10Gi"
  pvc_loki_size          = "20Gi"

  depends_on = [
    module.kube_namespaces,
    module.storageclass,
  ]
}


module "chart_loki" {
  source                           = "./modules/chart_loki"
  loki_helm_repo_url               = "https://grafana.github.io/helm-charts"
  loki_retention_period            = "720h"
  grafana_persistence_size         = "8Gi"
  loki_max_entries_limit_per_query = "50000"
  grafana_image_tag                = ""
  loki_helm_chart_version          = "2.10.2"
  loki_persistence_size            = "8Gi"
  loki_release_name                = "loki"
  monitoring_namespace             = "monitoring"
  storage_class_name               = "cosmotech-retain"
  loki_helm_chart_name             = "loki-stack"

  depends_on = [
    module.pvc_loki_stack,
    module.kube_namespaces,
  ]
}


module "pvc_keycloak_postgres" {
  source = "./modules/storage/pvc_keycloak_postgres"

  keycloak_namespace              = "keycloak"
  deploy_postgres_pvc             = true
  pvc_postgres_storage_class_name = "cosmotech-retain"
  pvc_postgres_size               = "20Gi"
  pvc_postgres_access_mode        = "ReadWriteOnce"

  depends_on = [
    module.kube_namespaces,
    module.storageclass,
  ]
}


module "chart_keycloak" {
  source = "./modules/chart_keycloak"

  keycloak_namespace          = "keycloak"
  keycloak_admin_user         = "admin"
  keycloak_ingress_hostname   = local.cluster_domain
  keycloak_postgres_user      = "keycloak"
  postgres_storage_class_name = "cosmotech-retain"
  pvc_postgres_keycloak_name  = "pvc-keycloak"

  postgres_helm_repo          = "https://charts.bitnami.com/bitnami"
  postgres_helm_chart         = "postgresql"
  postgres_helm_chart_version = "15.5.1"

  keycloak_helm_repo          = "https://charts.bitnami.com/bitnami"
  keycloak_helm_chart         = "keycloak"
  keycloak_helm_chart_version = "21.3.1"

  depends_on = [
    module.kube_namespaces
  ]
}


module "pvc_harbor" {
  source                        = "./modules/storage/pvc_harbor"
  harbor_namespace              = "harbor"
  pvc_harbor_storage_class_name = "cosmotech-retain"

  depends_on = [
    module.storageclass
  ]
}


module "chart_harbor" {
  source = "./modules/chart_harbor"
  hostname = var.hostname

  harbor_helm_repo          = "oci://registry-1.docker.io/bitnamicharts"
  harbor_helm_chart         = "harbor"
  harbor_helm_chart_version = "26.8.5"

  postgres_helm_repo          = "https://charts.bitnami.com/bitnami"
  postgres_helm_chart         = "postgresql"
  postgres_helm_chart_version = "15.5.1"

  redis_helm_repo          = "https://charts.bitnami.com/bitnami"
  redis_helm_chart         = "redis"
  redis_helm_chart_version = "17.3.14"

  depends_on = [
    module.pvc_harbor,
    module.kube_namespaces,
  ]
}