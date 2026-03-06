terraform {
  backend "s3" {
    key    = "$TEMPLATE_state_file_name"
    bucket = "cosmotech-states"
    region = "$TEMPLATE_cluster_region"
  }
}

provider "aws" {
  region = var.cluster_region
}

locals {
  cloud_identity = {
    "eks.amazonaws.com/role-arn" = data.terraform_remote_state.terraform_cluster.outputs.aws_irsa_role_arn
  }

  lb_annotations = {
    "service.beta.kubernetes.io/aws-load-balancer-type"                              = "nlb"
    "service.beta.kubernetes.io/aws-load-balancer-backend-protocol"                  = "tcp"
    "service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled" = "true"
    "service.beta.kubernetes.io/aws-load-balancer-eip-allocations"                   = "eipalloc-03e2805bc83e3b481"
    "service.beta.kubernetes.io/aws-load-balancer-scheme"                            = "internet-facing"
    "service.beta.kubernetes.io/aws-load-balancer-subnets"                           = "subnet-02b5d6e252d7f60e7"
  }

  lb_ip = null
}


module "storage" {
  source = "git::https://github.com/cosmo-tech/terraform-aws.git//terraform-cluster/modules/storage"

  for_each = var.cloud_provider == "aws" ? local.persistences : {}

  namespace          = each.value.namespace
  resource           = "${var.cluster_name}-${each.key}"
  size               = each.value.size
  storage_class_name = local.storage_class_name
  region             = var.cluster_region
  cluster_name       = var.cluster_name
  cloud_provider     = var.cloud_provider
}