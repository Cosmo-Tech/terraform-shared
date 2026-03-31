terraform {
  required_providers {
    kubectl = {
      source  = "alekc/kubectl"
      version = "~> 2.1.3"
    }
  }
}


# 2. CLUSTERISSUER
# HTTP-01 challenge: https://cert-manager.io/docs/configuration/acme/http01
data "template_file" "clusterissuer_prod_http01" {
  count = var.cloud_provider == "kob" ? 0 : 1

  template = file("${path.module}/clusterissuer.http01.yaml")
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


# 3-2. CERTIFICATE
resource "kubectl_manifest" "certificate" {
  count = var.cloud_provider == "kob" ? 0 : 1

  yaml_body = data.template_file.certificate.rendered

  depends_on = [kubectl_manifest.letsencrypt_prod_http01[0]]
}
