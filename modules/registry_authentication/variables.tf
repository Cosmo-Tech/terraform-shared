variable "image_registries" {
  type = map(object({
    server   = string
    username = optional(string)
    password = optional(string)
  }))
  default = {}
}

variable "image_registry_auth_secret_source_namespace" {
  type = string
}

variable "namespaces" {
  description = "List of target namespaces where registry secrets must be duplicated"
  type        = list(string)
}