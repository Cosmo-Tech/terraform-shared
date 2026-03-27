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

data "kubernetes_resource" "metallb_pool" {
  api_version = "metallb.io/v1beta1"
  kind        = "IPAddressPool"
  metadata {
    name      = "cosmo-pool"
    namespace = "metallb-system"
  }
}

locals {
  cloud_identity = {}

  lb_annotations = {
    "metallb.universe.tf/address-pool" = "cosmo-pool"
  }

  # Get the IP from the L2Advertisement of Metallb
  lb_ip = split("/", data.kubernetes_resource.metallb_pool.object.spec.addresses[0])[0]
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
