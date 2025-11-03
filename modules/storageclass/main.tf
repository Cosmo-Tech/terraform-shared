locals {
  is_gcp   = var.cloud_provider == "gcp"
  is_azure = var.cloud_provider == "azure"
  is_aws   = var.cloud_provider == "aws"
  is_bare  = var.cloud_provider == "bare"
}

# Main Persistent Disk StorageClass
resource "kubernetes_storage_class" "cosmotech_retain" {
  count = var.deploy_storageclass && (
    local.is_gcp || local.is_azure || local.is_aws || local.is_bare
  ) ? 1 : 0

  metadata {
    name = "cosmotech-retain"
    labels = {
      "cloud-provider" = var.cloud_provider
      "managed-by"     = "terraform"
    }
  }

  storage_provisioner = (
    local.is_gcp ? var.storageclass_provisioner_gcp :
    local.is_azure ? var.storageclass_provisioner_azure :
    local.is_aws ? var.storageclass_provisioner_aws :
    local.is_bare ? var.storageclass_provisioner_bare :
    "invalid-provisioner"
  )

  reclaim_policy         = "Retain"
  allow_volume_expansion = true
  volume_binding_mode    = "WaitForFirstConsumer"
}

# NFS / Network StorageClass (Filestore / AzureFile / EFS)
resource "kubernetes_storage_class" "cosmotech_filestore_retain" {
  count = var.deploy_storageclass_nfs && (
    local.is_gcp || local.is_azure || local.is_aws
  ) ? 1 : 0

  metadata {
    name = "cosmotech-filestore-retain"
    labels = {
      "cloud-provider" = var.cloud_provider
      "managed-by"     = "terraform"
    }
  }

  storage_provisioner = (
    local.is_gcp ? "filestore.csi.storage.gke.io" :
    local.is_azure ? "file.csi.azure.com" :
    local.is_aws ? "efs.csi.aws.com" :
    "invalid-provisioner"
  )

  reclaim_policy         = "Retain"
  allow_volume_expansion = true
  volume_binding_mode    = "WaitForFirstConsumer"
}
