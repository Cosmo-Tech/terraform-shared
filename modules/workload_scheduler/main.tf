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
    NAMESPACE                = var.namespace
    SCALER_TIME_ZONE         = var.scaler_time_zone
    SCALE_UP_CRON_SCHEDULE   = var.scale_up_cron_schedule
    SCALE_DOWN_CRON_SCHEDULE = var.scale_down_cron_schedule
  }
}

resource "kubectl_manifest" "scaling_state_pvc" {
  count           = var.enable_workload_scheduler ? 1 : 0
  validate_schema = false
  yaml_body       = templatefile("${path.module}/kube_objects/scaling-state-pvc.yaml", local.chart_values)
}

resource "kubectl_manifest" "workload_scaler_rbac" {
  count           = var.enable_workload_scheduler ? 1 : 0
  validate_schema = false
  yaml_body       = templatefile("${path.module}/kube_objects/workload-scaler-rbac.yaml", local.chart_values)
}

resource "kubectl_manifest" "scale_down_cronjob" {
  count           = var.enable_workload_scheduler ? 1 : 0
  validate_schema = false
  yaml_body       = templatefile("${path.module}/kube_objects/scale-down-cronjob.yaml", local.chart_values)
}

resource "kubectl_manifest" "scale_up_cronjob" {
  count           = var.enable_workload_scheduler ? 1 : 0
  validate_schema = false
  yaml_body       = templatefile("${path.module}/kube_objects/scale-up-cronjob.yaml", local.chart_values)
}