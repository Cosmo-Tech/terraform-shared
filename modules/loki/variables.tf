variable "monitoring_namespace" {
  type        = string
  description = "Namespace where the monitoring stack (Loki, Grafana, Promtail) is deployed."
}

variable "loki_release_name" {
  type        = string
  description = "Name of the Helm release for Loki."
}

variable "loki_persistence_size" {
  type        = string
  description = "Persistent volume size for Loki data."
}

variable "grafana_persistence_size" {
  type        = string
  description = "Persistent volume size for Grafana data."
}

variable "loki_retention_period" {
  type        = string
  description = "Retention period for Loki logs."
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

variable "loki_max_entries_limit_per_query" {
  type        = number
  description = "Maximum number of entries allowed per Loki query."
}

variable "storage_class_name" {
  type        = string
  description = "Storage class name for Grafana PVC."
}

variable "grafana_image_tag" {
  type        = string
  description = "Grafana image tag compatible with Loki version."
}
