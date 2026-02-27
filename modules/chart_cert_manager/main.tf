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


data "template_file" "cert_values" {
  template = file("${path.module}/values.yaml")
  vars = {
    service_annotations = yamlencode(var.service_annotations)
  }
}


data "template_file" "clusterissuer_prod" {
  count    = var.cloud_provider == "kob" ? 0 : 1
  template = file("${path.module}/kube_objects/clusterissuer.yaml")
  vars = {
    certificate_email = var.certificate_email
  }
}

data "template_file" "clusterissuer_onprem_prod" {
  count    = var.cloud_provider == "kob" ? 1 : 0
  template = file("${path.module}/kube_objects/clusterissuer_onprem.yaml")
  vars = {
    certificate_email   = var.certificate_email
    domain_zone         = var.domain_zone
    resource_group_name = var.resource_group_name
    subscription_id     = var.subscription_id
    tenant_id           = var.tenant_id
    client_id           = var.client_id

  }
}

resource "kubernetes_secret" "onprem_issuer" {
  count = var.cloud_provider == "kob" ? 1 : 0

  metadata {
    name      = "azure-dns-secret"
    namespace = "cert-manager"
  }

  data = {
    client-secret = var.azure_dns_secret
  }

  type = "Opaque"
}

data "template_file" "certificate" {
  template = file("${path.module}/kube_objects/certificate.yaml")
  vars = {
    certificate_email = var.certificate_email
    cluster_domain    = var.cluster_domain
  }
}

# 1. CERT-MANAGER
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

# 2. PROD ISSUER
resource "kubectl_manifest" "letsencrypt_prod" {
  count     = var.cloud_provider == "kob" ? 0 : 1
  yaml_body = data.template_file.clusterissuer_prod[0].rendered

  depends_on = [
    helm_release.cert_manager
  ]
}

resource "kubectl_manifest" "letsencrypt_onprem_prod" {
  count     = var.cloud_provider == "kob" ? 1 : 0
  yaml_body = data.template_file.clusterissuer_onprem_prod[0].rendered

  depends_on = [
    helm_release.cert_manager
  ]
}

resource "kubectl_manifest" "certificate" {
  count     = var.cloud_provider == "kob" ? 0 : 1
  yaml_body = data.template_file.certificate.rendered

  depends_on = [
    kubectl_manifest.letsencrypt_prod[0]
  ]
}

resource "kubectl_manifest" "certificate_onprem" {
  count     = var.cloud_provider == "kob" ? 1 : 0
  yaml_body = data.template_file.certificate.rendered

  depends_on = [
    kubectl_manifest.letsencrypt_onprem_prod[0]
  ]
}