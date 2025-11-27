variable "namespaces" {
  description = "List of Kubernetes namespaces to create"
  type        = list(string)
}

variable "labels" {
  description = "Optional labels to apply to all namespaces"
  type        = map(string)
  default     = {}
}