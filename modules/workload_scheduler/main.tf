
resource "helm_release" "kubernetes_workload_scaler" {
  name      = "kws"
  namespace = "default"

  repository = var.chart_repository
  chart      = var.chart_name
  version    = var.chart_tag

  create_namespace = false
  wait             = true
  timeout          = 600

  values = [
    templatefile("${path.module}/templates/values.yaml", {
      KWS_SCALE_DOWN_SCHEDULE    = var.kws_scale_down_schedule
      KWS_SCALE_UP_SCHEDULE      = var.kws_scale_up_schedule
      IMAGE_REGISTRY_AUTH_SECRET = var.image_registry_auth_secret
      IMAGE_REPOSITORY_PREFIX    = var.image_repository_prefix
      KWS_IMAGE_TAG              = var.kws_image_tag
    })
  ]
}
