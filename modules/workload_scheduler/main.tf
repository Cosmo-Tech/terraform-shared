terraform {
  required_providers {
    kubectl = {
      source  = "alekc/kubectl"
      version = "~> 2.1.3"
    }
  }
}

locals {
  objects_values = {
    NAMESPACE                = var.namespace
    SCALER_TIME_ZONE         = var.scaler_time_zone
    SCALE_UP_CRON_SCHEDULE   = var.scale_up_cron_schedule
    SCALE_DOWN_CRON_SCHEDULE = var.scale_down_cron_schedule
  }
}

resource "kubectl_manifest" "cluster_role_binding" {
  count           = var.enable_workload_scheduler ? 1 : 0
  validate_schema = false
  yaml_body       = templatefile("${path.module}/kube_objects/cluster-role-binding.yaml", local.objects_values)
}


resource "kubectl_manifest" "cluster_role" {
  count           = var.enable_workload_scheduler ? 1 : 0
  validate_schema = false
  yaml_body       = templatefile("${path.module}/kube_objects/cluster-role.yaml", local.objects_values)
}


resource "kubectl_manifest" "cluster_role_binding" {
  count           = var.enable_workload_scheduler ? 1 : 0
  validate_schema = false
  yaml_body       = templatefile("${path.module}/kube_objects/cluster-role-binding.yaml", local.objects_values)
}


resource "kubectl_manifest" "cronjob-scale-down" {
  count           = var.enable_workload_scheduler ? 1 : 0
  validate_schema = false
  yaml_body       = templatefile("${path.module}/kube_objects/cronjob-scale-down.yaml", local.objects_values)
}


resource "kubectl_manifest" "cronjob-scale-up" {
  count           = var.enable_workload_scheduler ? 1 : 0
  validate_schema = false
  yaml_body       = templatefile("${path.module}/kube_objects/cronjob-scale-up.yaml", local.objects_values)
}


resource "kubectl_manifest" "pvc" {
  count           = var.enable_workload_scheduler ? 1 : 0
  validate_schema = false
  yaml_body       = templatefile("${path.module}/kube_objects/pvc.yaml", local.objects_values)
}


resource "kubectl_manifest" "service-account" {
  count           = var.enable_workload_scheduler ? 1 : 0
  validate_schema = false
  yaml_body       = templatefile("${path.module}/kube_objects/service_account.yaml", local.objects_values)
}
