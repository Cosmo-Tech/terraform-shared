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
}


variable "cloud_provider" {
  description = "Cloud provider name where the deployment takes place"
  type        = string

  validation {
    condition     = contains(["bare", "azure", "aws", "gcp"], var.cloud_provider)
    error_message = "Valid values for 'cloud_provider' are: \n- bare\n- azure\n- aws\n- gcp"
  }
}

variable "cluster_name" {
  description = "Kubernetes cluster name where to perform installation"
  type        = string
}

variable "cluster_region" {
  description = "Cloud provider region where is located the cluster"
  type        = string
}

variable "domain_zone" {
  description = "Domain zone containing the cluster domain"
  type        = string
}

variable "certificate_email" {
  description = "Email for Let's Encrypt"
  type        = string
}