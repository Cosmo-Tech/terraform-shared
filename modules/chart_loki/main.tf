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
    MONITORING_NAMESPACE             = var.monitoring_namespace
    LOKI_RETENTION_PERIOD            = var.loki_retention_period
    LOKI_PERSISTENCE_SIZE            = var.loki_persistence_size
    LOKI_MAX_ENTRIES_LIMIT_PER_QUERY = var.loki_max_entries_limit_per_query
    LOKI_PVC_NAME                    = "pvc-loki"
    STORAGE_CLASS                    = var.storage_class_name
    GRAFANA_PERSISTENCE_SIZE         = var.grafana_persistence_size
    GRAFANA_PVC_NAME                 = "pvc-grafana"
    GRAFANA_IMAGE_TAG                = var.grafana_image_tag
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
  namespace    = var.monitoring_namespace
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
