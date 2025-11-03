variable "project_name" {
  description = "Base project name prefix for naming resources"
  type        = string
}

variable "namespace" {
  description = "Namespace for deploying the Helm release"
  type        = string
}

variable "api_dns_name" {
  description = "API DNS name"
  type        = string
}

variable "tls_secret_name" {
  description = "TLS secret name for Prometheus ingress"
  type        = string
}

variable "redis_host_namespace" {
  description = "Namespace where Redis is deployed"
  type        = string
}

variable "redis_port" {
  description = "Redis port"
  type        = number
  default     = 6379
}

variable "redis_admin_password" {
  description = "Redis admin password (leave empty to auto-generate)"
  type        = string
  default     = ""
}

variable "prom_admin_password" {
  description = "Prometheus admin password (leave empty to auto-generate)"
  type        = string
  default     = ""
}

variable "prom_replicas_number" {
  description = "Number of Prometheus replicas"
  type        = number
  default     = 1
}

variable "prom_storage_resource_request" {
  description = "Prometheus storage resource request"
  type        = string
  default     = "5Gi"
}

variable "prom_storage_class_name" {
  description = "Storage class name for Prometheus PVC"
  type        = string
}

variable "prom_cpu_mem_limits" {
  description = "Prometheus CPU and memory limits"
  type        = map(string)
  default = {
    cpu    = "500m"
    memory = "512Mi"
  }
}

variable "prom_cpu_mem_request" {
  description = "Prometheus CPU and memory requests"
  type        = map(string)
  default = {
    cpu    = "250m"
    memory = "256Mi"
  }
}

variable "prom_retention" {
  description = "Prometheus retention period"
  type        = string
  default     = "15d"
}

variable "helm_release_name" {
  description = "Helm release name for Prometheus"
  type        = string
  default     = "kube-prometheus-stack"
}

variable "helm_repo_url" {
  description = "Helm repository URL for Prometheus chart"
  type        = string
  default     = "https://prometheus-community.github.io/helm-charts"
}

variable "helm_chart_name" {
  description = "Helm chart name"
  type        = string
  default     = "kube-prometheus-stack"
}

variable "helm_chart_version" {
  description = "Helm chart version"
  type        = string
}