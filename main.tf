locals {
  cloud_identity = (
    var.cloud_provider == "gcp" ? { "iam.gke.io/gcp-service-account" = data.terraform_remote_state.terraform_cluster.outputs.node_sa_email } :
    var.cloud_provider == "aws" ? { "eks.amazonaws.com/role-arn" = data.terraform_remote_state.terraform_cluster.outputs.aws_irsa_role_arn } :
    var.cloud_provider == "azure" ? { "azure.workload.identity/client-id" = null } :
    null
  )

  lb_annotations = (
    var.cloud_provider == "gcp" ? {
      "service.beta.kubernetes.io/google-load-balancer-ip" = data.terraform_remote_state.terraform_cluster.outputs.platform_lb_ip
    } :
    var.cloud_provider == "aws" ? {
      "service.beta.kubernetes.io/aws-load-balancer-type"                              = "nlb"
      "service.beta.kubernetes.io/aws-load-balancer-backend-protocol"                  = "tcp"
      "service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled" = "true"
      "service.beta.kubernetes.io/aws-load-balancer-eip-allocations"                   = "eipalloc-03e2805bc83e3b481"
      "service.beta.kubernetes.io/aws-load-balancer-scheme"                            = "internet-facing"
      "service.beta.kubernetes.io/aws-load-balancer-subnets"                           = "subnet-02b5d6e252d7f60e7"
    } :
    var.cloud_provider == "azure" ? {
      # "service.beta.kubernetes.io/azure-load-balancer-resource-group"            = data.terraform_remote_state.terraform_cluster.outputs.node_resource_group
      "service.beta.kubernetes.io/azure-load-balancer-resource-group"            = [for node in data.kubernetes_nodes.all_nodes.nodes : node.metadata.0.labels].0["kubernetes.azure.com/cluster"]
      "service.beta.kubernetes.io/azure-load-balancer-health-probe-request-path" = "/healthz"
    } :
    {}
  )

  lb_ip = (
    var.cloud_provider == "gcp" ? data.terraform_remote_state.terraform_cluster.outputs.platform_lb_ip :
    var.cloud_provider == "aws" ? null : # AWS LB IP is dynamic, use annotation/type instead
    # var.cloud_provider == "azure" ? data.terraform_remote_state.terraform_cluster.outputs.platform_lb_ip :
    # var.cloud_provider == "azure" ? data.azurerm_dns_a_record.cluster.records :
    var.cloud_provider == "azure" ? data.azurerm_public_ip.lb_ip.ip_address :
    null
  )

  cluster_domain = "${var.cluster_name}.${var.domain_zone}"

  storage_class_name = "cosmotech-retain"
  persistences = {
    keycloak = {
      size = 50
      pvc  = "pvc-keycloak"
    }
    loki = {
      size = 50
      pvc  = "pvc-loki"
    }
    grafana = {
      size = 10
      pvc  = "pvc-grafana"
    }
    prometheusstack = {
      size = 100
      pvc  = "pvc-prometheusstack"
    }
    harbor-redis = {
      size = 10
      pvc  = "pvc-harbor-redis"
    }
    harbor-postgresql = {
      size = 10
      pvc  = "pvc-harbor-postgresql"
    }
    harbor-registry = {
      size = 50
      pvc  = "pvc-harbor-registry"
    }
    harbor-jobservice = {
      size = 10
      pvc  = "pvc-harbor-jobservice"
    }
    harbor-chartmuseum = {
      size = 10
      pvc  = "pvc-harbor-chartmuseum"
    }
    harbor-trivy = {
      size = 10
      pvc  = "pvc-harbor-trivy"
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
    "harbor"
  ]
}



module "storage_azure" {
  # source = "git::https://github.com/cosmo-tech/terraform-azure.git//terraform-cluster/modules/storage"
  source = "git::https://github.com/cosmo-tech/terraform-azure.git//terraform-cluster/modules/storage?ref=ggon/compute"

  for_each = var.cloud_provider == "azure" ? local.persistences : {}

  tenant             = ""
  resource           = each.key
  size               = each.value.size
  storage_class_name = local.storage_class_name
  region             = var.cluster_region
  cluster_name       = var.cluster_name
  cloud_provider     = var.cloud_provider
}


# module "storage_aws" {
#   source = "git::https://github.com/cosmo-tech/terraform-azure.git//terraform-cluster/modules/storage"
#   # source = "git::https://github.com/cosmo-tech/terraform-aws.git//terraform-cluster/modules/storage"

#   for_each = var.cloud_provider == "aws" ? local.persistences : {}

#   tenant             = module.kube_namespace.tenant
#   resource           = each.key
#   size               = each.value.size
#   storage_class_name = local.storage_class_name
#   region             = var.cluster_region
#   cluster_name       = var.cluster_name
#   cloud_provider     = var.cloud_provider
# }


# module "storage_gcp" {
#   source = "git::https://github.com/cosmo-tech/terraform-azure.git//terraform-cluster/modules/storage"
#   # source = "git::https://github.com/cosmo-tech/terraform-gcp.git//terraform-cluster/modules/storage"

#   for_each = var.cloud_provider == "gcp" ? local.persistences : {}

#   tenant             = module.kube_namespace.tenant
#   resource           = each.key
#   size               = each.value.size
#   storage_class_name = local.storage_class_name
#   region             = var.cluster_region
#   cluster_name       = var.cluster_name
#   cloud_provider     = var.cloud_provider
# }


# module "storage_onprem" {
#   source = "git::https://github.com/cosmo-tech/terraform-azure.git//terraform-cluster/modules/storage"
#   # source = "git::https://github.com/cosmo-tech/terraform-onprem.git//terraform-cluster/modules/storage"

#   for_each = var.cloud_provider == "onprem" ? local.persistences : {}

#   tenant             = module.kube_namespace.tenant
#   resource           = each.key
#   size               = each.value.size
#   storage_class_name = local.storage_class_name
#   region             = var.cluster_region
#   cluster_name       = var.cluster_name
#   cloud_provider     = var.cloud_provider
# }


# Timer to wait for storage to be created before continue
resource "time_sleep" "timer" {
  create_duration = "30s"
}


module "storageclass" {
  source = "./modules/kube_storageclass"

  cloud_provider          = var.cloud_provider
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
    module.kube_namespaces
  ]
}


module "chart_cert_manager" {
  source = "./modules/chart_cert_manager"

  service_annotations = local.cloud_identity
  certificate_email   = var.certificate_email
  cluster_domain      = local.cluster_domain

  depends_on = [
    module.kube_namespaces
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
  pvc_redis         = local.persistences.harbor-redis["pvc"]
  size_redis        = local.persistences.harbor-redis["size"]
  pvc_postgresql    = local.persistences.harbor-postgresql["pvc"]
  size_postgresql   = local.persistences.harbor-postgresql["size"]
  pvc_registry      = local.persistences.harbor-registry["pvc"]
  size_registry     = local.persistences.harbor-registry["size"]
  pvc_jobservice    = local.persistences.harbor-jobservice["pvc"]
  size_jobservice   = local.persistences.harbor-jobservice["size"]
  pvc_chartmuseum   = local.persistences.harbor-chartmuseum["pvc"]
  size_chartmuseum  = local.persistences.harbor-chartmuseum["size"]
  pvc_trivy         = local.persistences.harbor-trivy["pvc"]
  size_trivy        = local.persistences.harbor-trivy["size"]

  depends_on = [
    module.kube_namespaces,
    module.storageclass,
  ]
}


module "chart_keycloak" {
  source = "./modules/chart_keycloak"

  namespace = "keycloak"

  keycloak_ingress_hostname = local.cluster_domain

  pvc               = local.persistences.keycloak["pvc"]
  pvc_storage_class = local.storage_class_name

  keycloak_helm_repo          = "https://charts.bitnami.com/bitnami"
  keycloak_helm_chart         = "keycloak"
  keycloak_helm_chart_version = "21.3.1"

  postgres_helm_repo          = "https://charts.bitnami.com/bitnami"
  postgres_helm_chart         = "postgresql"
  postgres_helm_chart_version = "15.5.1"

  depends_on = [
    module.kube_namespaces,
    module.storageclass,
  ]
}


module "chart_loki" {
  source = "./modules/chart_loki"

  namespace = "monitoring"

  loki_helm_repo_url      = "https://grafana.github.io/helm-charts"
  loki_release_name       = "loki"
  loki_helm_chart_name    = "loki-stack"
  loki_helm_chart_version = "2.10.2"

  pvc_storage_class = local.storage_class_name
  pvc_loki          = local.persistences.loki["pvc"]
  size_loki         = local.persistences.loki["size"]
  pvc_grafana       = local.persistences.loki["pvc"]
  size_grafana      = local.persistences.loki["size"]

  depends_on = [
    module.kube_namespaces,
    module.storageclass,
  ]
}


module "chart_prometheus_stack" {
  source = "./modules/chart_prometheus_stack"

  namespace = "monitoring"

  cluster_domain = local.cluster_domain

  helm_repo_url      = "https://prometheus-community.github.io/helm-charts"
  helm_release_name  = "kube-prometheus-stack"
  helm_chart_name    = "kube-prometheus-stack"
  helm_chart_version = "65.1.0"

  pvc_storage_class = local.storage_class_name
  size              = local.persistences.prometheusstack["size"]
  # NOTE: kube-prometheus-stack 65.1.0 is not able to claim an existing PV, newers versions can handle it.
  # pvc               = local.persistences.prometheusstack["pvc"]

  depends_on = [
    module.kube_namespaces,
    module.storageclass,
  ]
}