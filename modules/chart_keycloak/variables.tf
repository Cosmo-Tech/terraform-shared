variable "namespace" {
  type = string
}

variable "image_registry" {
  type = string
}

variable "image_registry_auth_secret" {
  type = string
}


# -- Keycloak itself
variable "chart_keycloak_repository" {
  type = string
}

variable "chart_keycloak_name" {
  type = string
}

variable "chart_keycloak_tag" {
  type = string
}

variable "chart_keycloak_release" {
  type = string
}
# -- Keycloak itself


# -- Keycloak PostgreSQL
variable "chart_postgresql_repository" {
  type = string
}

variable "chart_postgresql_name" {
  type = string
}

variable "chart_postgresql_tag" {
  type = string
}

variable "chart_postgresql_release" {
  type = string
}
# -- Keycloak PostgreSQL


variable "keycloak_ingress_hostname" {
  description = "Ingress hostname for Keycloak"
  type        = string
}

variable "keycloak_admin_password" {
  description = "Optional Keycloak admin password; generated if empty"
  type        = string
  default     = ""
}

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