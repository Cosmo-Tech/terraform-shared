output "namespaces" {
  description = "All created namespaces"
  value       = keys(kubernetes_namespace.this)
}
