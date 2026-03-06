terraform {
  backend "gcs" {
    bucket = "cosmotech-states"
    prefix = "$TEMPLATE_state_file_name"
  }
}

provider "google" {
  project = var.project_id
  region  = var.cluster_region
}

variable "project_id" { type = string }

data "terraform_remote_state" "terraform_cluster" {
  backend = "gcs"
  config = {
    bucket = "cosmotech-states"
    # prefix = ""
  }
}

data "google_client_config" "current" {}

locals {
  cloud_identity = {
    "iam.gke.io/gcp-service-account" = data.terraform_remote_state.terraform_cluster.outputs.node_sa_email
  }

  lb_annotations = {
    "service.beta.kubernetes.io/google-load-balancer-ip" = data.terraform_remote_state.terraform_cluster.outputs.platform_lb_ip
  }

  lb_ip = data.terraform_remote_state.terraform_cluster.outputs.platform_lb_ip
}

module "storage" {
  source = "git::https://github.com/cosmo-tech/terraform-gcp.git//terraform-cluster/modules/storage"

  for_each = var.cloud_provider == "gcp" ? local.persistences : {}

  namespace          = each.value.namespace
  resource           = "${var.cluster_name}-${each.key}"
  size               = each.value.size
  storage_class_name = local.storage_class_name
  region             = var.cluster_region
  cluster_name       = var.cluster_name
  cloud_provider     = var.cloud_provider
}