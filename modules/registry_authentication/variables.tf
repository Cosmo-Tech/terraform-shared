
variable "image_registry" {
  type = string
}

variable "image_registry_auth_secret" {
  description = "Kubernetes secret that contains the image registry authentication"
  type        = string
}

variable "image_registry_username" {
  description = "Image registry username (must be provided by your Administrator)"
  type        = string
  sensitive   = true
}

variable "image_registry_password" {
  description = "Image registry password (must be provided by your Administrator)"
  type        = string
  sensitive   = true
}

variable "image_registry_auth_secret_source_namespace" {
  description = "Namespace that contains the source Kubernetes secret to duplicate in others namespaces (each namespaces must have their own secret to be able pull images)"
  type        = string
}
