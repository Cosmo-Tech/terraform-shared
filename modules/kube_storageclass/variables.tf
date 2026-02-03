variable "cloud_provider" {
  description = "Target cloud provider (gcp, azure, aws, or bare)"
  type        = string
  validation {
    condition     = contains(["gcp", "azure", "aws", "bare"], var.cloud_provider)
    error_message = "cloud_provider must be one of: gcp, azure, aws, or bare"
  }
}

variable "storage_class" {
  type = string
}

variable "deploy_storageclass" {
  description = "Whether to deploy the main Retain storage class"
  type        = bool
  default     = true
}

variable "deploy_storageclass_nfs" {
  description = "Whether to deploy the NFS/Filestore-style storage class"
  type        = bool
  default     = false
}

# -----------------------------------------------------
# Cloud provisioner defaults
# -----------------------------------------------------
variable "storageclass_provisioner_gcp" {
  type    = string
  default = "pd.csi.storage.gke.io"
}

variable "storageclass_provisioner_azure" {
  type    = string
  default = "disk.csi.azure.com"
}

variable "storageclass_provisioner_aws" {
  type    = string
  default = "ebs.csi.aws.com"
}

variable "storageclass_provisioner_bare" {
  description = "Provisioner for bare metal environments"
  type        = string
  default     = "kubernetes.io/no-provisioner"
}
