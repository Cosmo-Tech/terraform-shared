variable "pvc_namespace" {
  description = "Namespace for Grafana and Loki PVCs"
  type        = string
}

variable "deploy_grafana_pvc" {
  description = "Whether to deploy the Grafana PVC"
  type        = bool
  default     = true
}

variable "deploy_loki_pvc" {
  description = "Whether to deploy the Loki PVC"
  type        = bool
  default     = true
}

# Grafana
variable "pvc_grafana_access_mode" {
  description = "Access mode for Grafana PVC (ReadWriteOnce or ReadWriteMany)"
  type        = string
  default     = "ReadWriteOnce"
}

# variable "pvc_grafana_storage_class_name" {
#   description = "Storage class name for Grafana PVC"
#   type        = string
# }

variable "pvc_grafana_size" {
  description = "Storage size for Grafana PVC (e.g., 10Gi)"
  type        = string
  default     = "10Gi"
}

# Loki
variable "pvc_loki_access_mode" {
  description = "Access mode for Loki PVC (ReadWriteOnce or ReadWriteMany)"
  type        = string
  default     = "ReadWriteOnce"
}

variable "pvc_storage_class_name" {
  description = "Storage class name for Loki PVC"
  type        = string
}

variable "pvc_loki_size" {
  description = "Storage size for Loki PVC (e.g., 20Gi)"
  type        = string
  default     = "20Gi"
}
