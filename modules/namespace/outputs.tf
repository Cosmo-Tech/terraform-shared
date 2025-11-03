output "namespaces" {
  description = "Map of namespaces created"
  value       = { for ns, n in kubernetes_namespace.this : ns => n.metadata[0].name }
}