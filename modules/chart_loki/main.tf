terraform {
  required_providers {
    kubectl = {
      source  = "alekc/kubectl"
      version = "~> 2.1.3"
    }
  }
}


locals {
  chart_values = {
    NAMESPACE                 = var.namespace
    PERSISTENCE_STORAGE_CLASS = var.pvc_storage_class
    PERSISTENCE_LOKI_PVC      = var.pvc_loki
    PERSISTENCE_LOKI_SIZE     = var.size_loki
    PERSISTENCE_GRAFANA_PVC   = var.pvc_grafana
    PERSISTENCE_GRAFANA_SIZE  = var.size_grafana
  }
}


resource "time_sleep" "wait_for_cleanup" {
  destroy_duration = "10s"
}


resource "helm_release" "loki_stack" {
  name         = var.loki_release_name
  repository   = var.loki_helm_repo_url
  chart        = var.loki_helm_chart_name
  version      = var.loki_helm_chart_version
  namespace    = var.namespace
  reset_values = true

  values = [
    templatefile("${path.module}/values.yaml", local.chart_values)
  ]

  depends_on = [
    time_sleep.wait_for_cleanup
  ]
}


resource "kubectl_manifest" "loki_role" {
  validate_schema = false
  yaml_body       = templatefile("${path.module}/kube_objects/role.yaml", local.chart_values)
}


resource "kubectl_manifest" "loki_rolebinding" {
  validate_schema = false
  yaml_body       = templatefile("${path.module}/kube_objects/rolebinding.yaml", local.chart_values)
}
