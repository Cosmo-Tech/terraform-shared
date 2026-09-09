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
    MAIN_NAME                = "workload-scheduler"
    SCALER_TIME_ZONE         = var.scaler_time_zone
    SCALE_UP_CRON_SCHEDULE   = var.scale_up_cron_schedule
    SCALE_DOWN_CRON_SCHEDULE = var.scale_down_cron_schedule
    SCALER_IMAGE_TAG         = "alpine/k8s:1.36.0"
  }
}


resource "kubectl_manifest" "service_account" {
  validate_schema = false
  yaml_body       = templatefile("${path.module}/templates/service-account.yaml", local.objects_values)
}


resource "kubectl_manifest" "cluster_role" {
  validate_schema = false
  yaml_body       = templatefile("${path.module}/templates/cluster-role.yaml", local.objects_values)
}


resource "kubectl_manifest" "cluster_role_binding" {
  validate_schema = false
  yaml_body       = templatefile("${path.module}/templates/cluster-role-binding.yaml", local.objects_values)
}


resource "kubectl_manifest" "cronjob_scale_down" {
  validate_schema = false
  yaml_body       = templatefile("${path.module}/templates/cronjob-scale-down.yaml", local.objects_values)
}


resource "kubectl_manifest" "cronjob_scale_up" {
  validate_schema = false
  yaml_body       = templatefile("${path.module}/templates/cronjob-scale-up.yaml", local.objects_values)
}


resource "kubectl_manifest" "pvc" {
  validate_schema = false
  yaml_body       = templatefile("${path.module}/templates/pvc.yaml", local.objects_values)
}
