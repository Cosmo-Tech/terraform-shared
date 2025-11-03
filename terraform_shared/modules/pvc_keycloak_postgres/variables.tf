variable "keycloak_namespace" {
  description = "Namespace for Keycloak PostgreSQL PVC"
  type        = string
}

variable "deploy_postgres_pvc" {
  description = "Whether to deploy Keycloak PostgreSQL PVC"
  type        = bool
  default     = true
}

variable "pvc_postgres_access_mode" {
  description = "Access mode for Keycloak PostgreSQL PVC (ReadWriteOnce or ReadWriteMany)"
  type        = string
  default     = "ReadWriteOnce"
}

variable "pvc_postgres_storage_class_name" {
  description = "Storage class name for Keycloak PostgreSQL PVC"
  type        = string
}

variable "pvc_postgres_size" {
  description = "Storage size for Keycloak PostgreSQL PVC (e.g., 10Gi)"
  type        = string
  default     = "20Gi"
}
