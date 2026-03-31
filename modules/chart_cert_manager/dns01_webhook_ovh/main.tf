terraform {
  required_providers {
    kubectl = {
      source  = "alekc/kubectl"
      version = "~> 2.1.3"
    }
  }
}

locals {
  dns_challenge_provider = "ovh"
}


# Install required Helm Chart:
#   - https://github.com/aureq/cert-manager-webhook-ovh
#   - https://aureq.github.io/cert-manager-webhook-ovh/
data "template_file" "cert_values" {
  count = (var.cloud_provider == "kob" && var.dns_challenge_provider == local.dns_challenge_provider) ? 1 : 0

  template = file("${path.module}/values.yaml")
  vars = {
    service_annotations = yamlencode(var.service_annotations)
  }
}

resource "helm_release" "cert_manager" {
  count = (var.cloud_provider == "kob" && var.dns_challenge_provider == local.dns_challenge_provider) ? 1 : 0

  name             = "cert-manager-webhook-ovh"
  repository       = "https://aureq.github.io/cert-manager-webhook-ovh/"
  chart            = "cert-manager-webhook-ovh"
  version          = "0.9.5"
  namespace        = "cert-manager"
  create_namespace = true

  values = [
    data.template_file.cert_values.rendered
  ]
}


# 2. CLUSTERISSUER
# DNS-01 challenge: https://cert-manager.io/docs/configuration/acme/dns01
# This ClusterIssuer is meant to work with the chart "cert-manager-webhook-ovh"
resource "kubernetes_secret" "dns_challenge_webhook_ovh" {
  count = (var.cloud_provider == "kob" && var.dns_challenge_provider == local.dns_challenge_provider) ? 1 : 0

  metadata {
    name      = "dns-challenge"
    namespace = "cert-manager"
  }

  data = {
    groupName         = var.ovh_group_name
    applicationKey    = var.ovh_application_key
    applicationSecret = var.ovh_application_secret
    consumerKey       = var.ovh_consumer_key
  }

  type = "Opaque"
}

data "template_file" "clusterissuer_prod_dns01_webhook_ovh" {
  count = (var.cloud_provider == "kob" && var.dns_challenge_provider == local.dns_challenge_provider) ? 1 : 0

  template = file("${path.module}/clusterissuer.dns01.webhook.ovh.yaml")
  vars = {
    certificate_email      = var.certificate_email
    ovh_group_name         = kubernetes_secret.dns_challenge[0].data["groupName"]
    ovh_application_key    = kubernetes_secret.dns_challenge[0].data["applicationKey"]
    ovh_application_secret = kubernetes_secret.dns_challenge[0].data["applicationSecret"]
    ovh_consumer_key       = kubernetes_secret.dns_challenge[0].data["consumerKey"]
  }
}

resource "kubectl_manifest" "letsencrypt_prod_dns01_webhook_ovh" {
  count = (var.cloud_provider == "kob" && var.dns_challenge_provider == local.dns_challenge_provider) ? 1 : 0

  yaml_body = data.template_file.clusterissuer_prod_dns01_webhook_ovh[0].rendered

  depends_on = [
    helm_release.cert_manager
  ]
}


# 3-2. CERTIFICATE
resource "kubectl_manifest" "certificate_dns01_webhook_ovh" {
  count = (var.cloud_provider == "kob" && var.dns_challenge_provider == local.dns_challenge_provider) ? 1 : 0

  yaml_body = data.template_file.certificate.rendered

  depends_on = [kubectl_manifest.letsencrypt_prod_dns01_webhook_ovh[0]]
}
