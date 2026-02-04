# -----------------------------
# General
# -----------------------------
variable "namespace" {
  description = "Namespace for Keycloak deployment"
  type        = string
}

variable "keycloak_admin_password" {
  description = "Optional Keycloak admin password; generated if empty"
  type        = string
  default     = ""
}

variable "keycloak_ingress_hostname" {
  description = "Ingress hostname for Keycloak"
  type        = string
}

# -----------------------------
# PostgreSQL Config
# -----------------------------
variable "keycloak_postgres_password" {
  description = "Optional PostgreSQL user password; generated if empty"
  type        = string
  default     = ""
}

variable "keycloak_postgres_admin_password" {
  description = "Optional PostgreSQL admin password; generated if empty"
  type        = string
  default     = ""
}

variable "pvc_storage_class" {
  description = "Storage class for Keycloak PostgreSQL PVC"
  type        = string
}

variable "pvc" {
  description = "Existing PVC name for Keycloak PostgreSQL"
  type        = string
}

# -----------------------------
# Helm Charts
# -----------------------------
variable "postgres_helm_repo" {
  description = "Helm repository URL for PostgreSQL"
  type        = string
}

variable "postgres_helm_chart" {
  description = "PostgreSQL Helm chart name"
  type        = string
}

variable "postgres_helm_chart_version" {
  description = "PostgreSQL Helm chart version"
  type        = string
}

variable "keycloak_helm_repo" {
  description = "Helm repository URL for Keycloak"
  type        = string
}

variable "keycloak_helm_chart" {
  description = "Keycloak Helm chart name"
  type        = string
}

variable "keycloak_helm_chart_version" {
  description = "Keycloak Helm chart version"
  type        = string
}
