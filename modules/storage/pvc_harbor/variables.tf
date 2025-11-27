variable "harbor_namespace" {
  description = "Namespace for harbor PVC"
  type        = string
}

variable "deploy_harbor_pvc" {
  description = "Whether to deploy harbor PVC"
  type        = bool
  default     = true
}

variable "pvc_harbor_access_mode" {
  description = "Access mode for harbor PVC (ReadWriteOnce or ReadWriteMany)"
  type        = string
  default     = "ReadWriteOnce"
}

variable "pvc_harbor_storage_class_name" {
  description = "Storage class name for harbor PVC"
  type        = string
}

variable "pvc_harbor_size" {
  description = "Storage size for harbor PVC (e.g., 10Gi)"
  type        = string
  default     = "20Gi"
}
