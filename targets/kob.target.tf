terraform {
  backend "http" {
    update_method          = "PUT"
    lock_method            = "POST"
    unlock_method          = "DELETE"
    skip_cert_verification = true

    address        = "$TEMPLATE_state_url"
    lock_address   = "$TEMPLATE_state_url/lock"
    unlock_address = "$TEMPLATE_state_url/lock"
  }
}

variable "state_host" { type = string }

locals {
  cloud_identity = {}
  lb_annotations = {}
  lb_ip          = ""
}

module "storage_kob" {
  source = "git::https://github.com/cosmo-tech/terraform-onprem//terraform-cluster/modules/storage"

  for_each = var.cloud_provider == "kob" ? local.persistences : {}

  namespace          = each.value.namespace
  resource           = "${var.cluster_name}-${each.key}"
  size               = each.value.size
  storage_class_name = local.storage_class_name
  region             = var.cluster_region
  cloud_provider     = var.cloud_provider
}