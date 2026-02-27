variable "cloud_provider" {
  description = "Cloud provider name where the deployment takes place"
  type        = string

  validation {
    condition     = contains(["kob", "azure", "aws", "gcp"], var.cloud_provider)
    error_message = "Valid values for 'cloud_provider' are: \n- kob\n- azure\n- aws\n- gcp"
  }
}

variable "cluster_name" {
  description = "Kubernetes cluster name where to perform installation"
  type        = string
}

variable "cluster_region" {
  description = "Cloud provider region where is located the cluster"
  type        = string
}

variable "domain_zone" {
  description = "Domain zone containing the cluster domain"
  type        = string
}

variable "certificate_email" {
  description = "Email for Let's Encrypt"
  type        = string
}

variable "storage_class_name" {
  description = "to specify the storage class name"
  type        = string
}