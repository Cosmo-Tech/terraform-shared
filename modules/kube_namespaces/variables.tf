variable "namespaces" {
  description = "List of Kubernetes namespaces to create"
  type        = list(string)
}

variable "labels" {
  description = "Optional labels to apply to all namespaces"
  type        = map(string)
  default     = {}
}


## Registry auth secret to duplicate in all namespaces
variable "image_registry" {
  type = string
}

variable "image_registry_auth_secret" {
  type = string
}

variable "image_registry_auth_secret_source_namespace" {
  type = string
}
## Registry auth secret to duplicate in all namespaces
