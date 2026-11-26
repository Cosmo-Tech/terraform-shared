locals {
  is_gcp   = var.cloud_provider == "gcp"
  is_azure = var.cloud_provider == "azure"
  is_aws   = var.cloud_provider == "aws"
  is_kob   = var.cloud_provider == "kob"
}

# Main Persistent Disk StorageClass
resource "kubernetes_storage_class" "cosmotech_retain" {
  count = var.deploy_storageclass && (
    local.is_gcp || local.is_azure || local.is_aws || local.is_kob
  ) ? 1 : 0

  metadata {
    name = var.storage_class
    labels = {
      "cloud-provider" = var.cloud_provider
      "managed-by"     = "terraform"
    }
  }

  storage_provisioner = (
    local.is_gcp ? var.storageclass_provisioner_gcp :
    local.is_azure ? var.storageclass_provisioner_azure :
    local.is_aws ? var.storageclass_provisioner_aws :
    local.is_kob ? var.storageclass_provisioner_kob :
    "invalid-provisioner"
  )

  reclaim_policy         = "Retain"
  allow_volume_expansion = true
  volume_binding_mode    = "WaitForFirstConsumer"
}

# NFS / Network StorageClass (Filestore / AzureFile / EFS)
resource "kubernetes_storage_class" "cosmotech_filestore_retain" {
  count = var.deploy_storageclass_nfs && (
    local.is_gcp || local.is_azure || local.is_aws || local.is_kob
  ) ? 1 : 0

  metadata {
    name = var.storage_class_nfs
    labels = {
      "cloud-provider" = var.cloud_provider
      "managed-by"     = "terraform"
    }
  }

  storage_provisioner = (
    local.is_gcp ? var.file_storageclass_provisioner_gcp :
    local.is_azure ? var.file_storageclass_provisioner_azure :
    local.is_aws ? var.file_storageclass_provisioner_aws :
    local.is_kob ? var.file_storageclass_provisioner_kob :
    "invalid-provisioner"
  )

  parameters = local.is_aws ? {
    provisioningMode = "efs-ap"
    fileSystemId     = var.aws_efs_file_system_id
  } : null

  lifecycle {
    precondition {
      condition     = !local.is_aws || try(length(trimspace(var.aws_efs_file_system_id)) > 0, false)
      error_message = "aws_efs_file_system_id must identify an existing EFS filesystem when the AWS file StorageClass is enabled."
    }
  }

  reclaim_policy         = "Retain"
  allow_volume_expansion = true
  volume_binding_mode    = "WaitForFirstConsumer"
}
