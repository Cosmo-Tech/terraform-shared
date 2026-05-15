variable "namespace" {
  type = string
}

variable "image_registry" {
  type = string
}

variable "image_registry_auth_secret" {
  type = string
}

variable "chart_repository" {
  type = string
}

variable "chart_name" {
  type = string
}

variable "chart_tag" {
  type = string
}

variable "chart_release" {
  type = string
}

variable "cluster_domain" {
  description = "API DNS name"
  type        = string
}

variable "redis_admin_password" {
  description = "Redis admin password (leave empty to auto-generate)"
  type        = string
  default     = ""
}

variable "prometheus_admin_password" {
  description = "Prometheus admin password (leave empty to auto-generate)"
  type        = string
  default     = ""
}

variable "pvc_storage_class" {
  description = "Storage class name for Prometheus PVC"
  type        = string
}

variable "size_prometheus" {
  type = string
}

variable "pvc_prometheus" {
  type = string
}

variable "size_grafana" {
  type = string
}

variable "pvc_grafana" {
  type = string
}