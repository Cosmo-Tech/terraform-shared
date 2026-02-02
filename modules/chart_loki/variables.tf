variable "namespace" {
  type        = string
  description = "Namespace where the monitoring stack (Loki, Grafana, Promtail) is deployed."
}

variable "loki_release_name" {
  type        = string
  description = "Name of the Helm release for Loki."
}

variable "loki_helm_repo_url" {
  type        = string
  description = "Helm repository URL for the Loki chart."
}

variable "loki_helm_chart_name" {
  type        = string
  description = "Helm chart name for Loki."
}

variable "loki_helm_chart_version" {
  type        = string
  description = "Version of the Loki Helm chart to deploy."
}

variable "pvc_storage_class" {
  type = string
}

variable "pvc_loki" {
  type = string
}

variable "size_loki" {
  type = string
}

variable "pvc_grafana" {
  type = string
}

variable "size_grafana" {
  type = string
}
