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
        "service.beta.kubernetes.io/azure-load-balancer-resource-group" = data.terraform_remote_state.terraform_cluster.outputs.node_resource_group
        "service.beta.kubernetes.io/azure-load-balancer-health-probe-request-path" = "/healthz"
      } :
    {}
  )

  lb_ip = (
    var.cloud_provider == "gcp" ? data.terraform_remote_state.terraform_cluster.outputs.platform_lb_ip :
    var.cloud_provider == "aws" ? null : # AWS LB IP is dynamic, use annotation/type instead
    var.cloud_provider == "azure" ? data.terraform_remote_state.terraform_cluster.outputs.platform_lb_ip :
    null
  )
}
