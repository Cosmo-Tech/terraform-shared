terraform {
  backend "gcs" {
    bucket = "cosmotech-states"
    prefix = "gke-test-devops/shared-state"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

module "platform_dns" {
  source       = "./modules/dns_record"
  project_id   = "csm-dns"
  managed_zone = "gcp-platform-cosmotech-com"

  records = [
    {
      name    = "cluster.gcp.platform.cosmotech.com."
      type    = "A"
      rrdatas = [data.terraform_remote_state.terraform_cluster.outputs.platform_lb_ip]
    }
  ]
}

module "namespaces" {
  source = "./modules/namespace"

  namespaces = [
    "ingress-nginx",
    "cert-manager",
    "monitoring",
    "redis",
    "keycloak"
  ]

  labels = {
    "environment" = "shared"
    "team"        = "devops"
  }
}


module "helm_nginx" {
  source = "./modules/ingress_nginx"

  platform_lb_ip         = local.lb_ip
  cluster_endpoint       = data.terraform_remote_state.terraform_cluster.outputs.cluster_endpoint
  cluster_ca_certificate = data.terraform_remote_state.terraform_cluster.outputs.cluster_ca_certificate
  depends_on             = [module.platform_dns, module.namespaces]
  service_annotations    = local.cloud_identity
  lb_annotations         = local.lb_annotations
}

# MODULE 2: CERT BUNDLE
module "cert_bundle" {
  source = "./modules/cert_manager"

  service_annotations    = local.cloud_identity
  email                  = var.email
  cluster_endpoint       = data.terraform_remote_state.terraform_cluster.outputs.cluster_endpoint
  cluster_ca_certificate = data.terraform_remote_state.terraform_cluster.outputs.cluster_ca_certificate
  api_dns_name           = var.api_dns_name
  depends_on             = [module.namespaces]
}

module "prometheus_stack" {
  source = "./modules/prometheus_stack"

  project_name            = "cosmotech"
  namespace               = "monitoring"
  api_dns_name            = var.api_dns_name
  tls_secret_name         = "letsencrypt-prod"
  redis_host_namespace    = "redis"
  prom_storage_class_name = "cosmotech-retain"
  helm_chart_version      = "65.1.0"

  depends_on = [module.namespaces]
}

module "storageclass" {
  source = "./modules/storageclass"

  cloud_provider          = "gcp"
  deploy_storageclass     = true
  deploy_storageclass_nfs = true
}

module "pvc_loki_stack" {
  source        = "./modules/pvc_loki_stack"
  pvc_namespace = "monitoring"

  deploy_grafana_pvc = true
  deploy_loki_pvc    = true

  pvc_storage_class_name = "cosmotech-retain"

  pvc_grafana_size = "10Gi"
  pvc_loki_size    = "20Gi"
  depends_on       = [module.namespaces]
}

module "pvc_keycloak_postgres" {
  source = "./modules/pvc_keycloak_postgres"

  keycloak_namespace              = "keycloak"
  deploy_postgres_pvc             = true
  pvc_postgres_storage_class_name = "cosmotech-retain"
  pvc_postgres_size               = "20Gi"
  pvc_postgres_access_mode        = "ReadWriteOnce"
  depends_on                      = [module.namespaces]
}

module "keycloak" {
  source = "./modules/keycloak"

  keycloak_namespace          = "keycloak"
  keycloak_admin_user         = "admin"
  keycloak_ingress_hostname   = "cluster.gcp.platform.cosmotech.com"
  keycloak_postgres_user      = "keycloak"
  postgres_storage_class_name = "cosmotech-retain"
  pvc_postgres_keycloak_name  = "pvc-keycloak"

  postgres_helm_repo          = "https://charts.bitnami.com/bitnami"
  postgres_helm_chart         = "postgresql"
  postgres_helm_chart_version = "15.5.1"

  keycloak_helm_repo          = "https://charts.bitnami.com/bitnami"
  keycloak_helm_chart         = "keycloak"
  keycloak_helm_chart_version = "21.3.1"
  depends_on                  = [module.namespaces]
}
