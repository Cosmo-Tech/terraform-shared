output "storage_class_names" {
  description = "Names of created storage classes"
  value = compact([
    try(kubernetes_storage_class.cosmotech_retain[0].metadata[0].name, null),
    try(kubernetes_storage_class.cosmotech_filestore_retain[0].metadata[0].name, null)
  ])
}
