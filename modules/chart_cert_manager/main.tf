terraform {
  required_providers {
    kubectl = {
      source  = "alekc/kubectl"
      version = "~> 2.1.3"
    }
  }
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

resource "time_sleep" "wait_certmanager_crds" {
  create_duration = "60s"

  depends_on = [
    helm_release.cert_manager
  ]
}

# 2. CLUSTERISSUER -> created in submodules, depending on the chosen challenge and the ACME provider

# 3-1. CERTIFICATE
data "template_file" "certificate" {
  template = file("${path.module}/certificate.yaml")
  vars = {
    cluster_domain = var.cluster_domain
  }
}

# 3-2. CERTIFICATE -> created in submodules, depending on the chosen challenge and the ACME provider
