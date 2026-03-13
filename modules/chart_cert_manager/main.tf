terraform {
  required_providers {
    kubectl = {
      source  = "alekc/kubectl"
      version = "~> 2.1.3"
    }
  }
}


resource "time_sleep" "wait_certmanager_crds" {
  create_duration = "60s"

  depends_on = [
    helm_release.cert_manager
  ]
}


# 1. CERT-MANAGER
data "template_file" "cert_values" {
  template = file("${path.module}/values.yaml")
  vars = {
    service_annotations = yamlencode(var.service_annotations)
  }
}

resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  version          = "1.11.0"
  namespace        = "cert-manager"
  create_namespace = true

  values = [
    data.template_file.cert_values.rendered
  ]
}


# 2. (MAIN) CLUSTER ISSUER HTTP-01
# HTTP-01 challenges : https://cert-manager.io/docs/configuration/acme/http01/
data "template_file" "clusterissuer_prod_http01" {
  count = var.cloud_provider == "kob" ? 0 : 1

  template = file("${path.module}/kube_objects/clusterissuer.http01.yaml")
  vars = {
    certificate_email = var.certificate_email
  }
}

resource "kubectl_manifest" "letsencrypt_prod_http01" {
  count = var.cloud_provider == "kob" ? 0 : 1

  yaml_body = data.template_file.clusterissuer_prod_http01[0].rendered

  depends_on = [
    helm_release.cert_manager
  ]
}


# 2. (BIS) CLUSTER ISSUER DNS-01
# DNS-01 challenges : https://cert-manager.io/docs/configuration/acme/dns01/2
#
# Trick here is to duplicate the dns-challenge secret from terraform-onprem from default namespace to cert-manager namespace
# cert-manager requires to have this secret in its namespace.
# This is to avoid creating namespace cert-manager in terraform-onprem
data "kubernetes_secret" "dns_challenge_terraform_onprem" {
  metadata {
    name      = "dns-challenge-terraform-onprem"
    namespace = "default"
  }
}

resource "kubernetes_secret" "dns_challenge" {
  count = var.cloud_provider == "kob" ? 1 : 0

  metadata {
    name      = "dns-challenge"
    namespace = "cert-manager"
  }

  data = data.kubernetes_secret.dns_challenge_terraform_onprem.data

  type = "Opaque"
}

data "template_file" "clusterissuer_prod_dns01_azuredns" {
  count = (var.cloud_provider == "kob" && var.dns_challenge_provider == "azure") ? 1 : 0

  template = file("${path.module}/kube_objects/clusterissuer.dns01.azuredns.yaml")
  vars = {
    certificate_email   = var.certificate_email
    client_id           = kubernetes_secret.dns_challenge[0].data["client-id"]
    subscription_id     = kubernetes_secret.dns_challenge[0].data["subscription-id"]
    tenant_id           = kubernetes_secret.dns_challenge[0].data["tenant-id"]
    domain_zone         = kubernetes_secret.dns_challenge[0].data["domain-zone"]
    resource_group_name = kubernetes_secret.dns_challenge[0].data["domain-zone-rg"]
  }
}

resource "kubectl_manifest" "letsencrypt_prod_dns01_azuredns" {
  count = var.cloud_provider == "kob" ? 1 : 0

  yaml_body = data.template_file.clusterissuer_prod_dns01_azuredns[0].rendered

  depends_on = [
    helm_release.cert_manager
  ]
}


# 3. CERTIFICATE
data "template_file" "certificate" {
  template = file("${path.module}/kube_objects/certificate.yaml")
  vars = {
    cluster_domain = var.cluster_domain
  }
}

resource "kubectl_manifest" "certificate" {
  count = var.cloud_provider == "kob" ? 0 : 1

  yaml_body = data.template_file.certificate.rendered

  depends_on = [
    kubectl_manifest.letsencrypt_prod_http01[0]
  ]
}

resource "kubectl_manifest" "certificate_dns01_azuredns" {
  count = var.cloud_provider == "kob" ? 1 : 0

  yaml_body = data.template_file.certificate.rendered

  depends_on = [
    kubectl_manifest.letsencrypt_prod_dns01_azuredns[0]
  ]
}
