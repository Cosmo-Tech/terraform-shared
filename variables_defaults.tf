# This file allows to fix defaults values, and also allow to override them from terraform.tfvars, CLI arguments or TF_VAR env variables.


# Registry
variable "image_registry" { default = "cgr.dev" }
variable "image_registry_auth_secret" { default = "registry-auth-cgrdev" }


# cert-manager
variable "certmanager_chart_repository" { default = "oci://cgr.dev/cosmotech/iamguarded-charts" }
variable "certmanager_chart_name" { default = "cert-manager" }
variable "certmanager_chart_tag" { default = "1.5.14" }


# Harbor
variable "harbor_chart_repository" { default = "oci://cgr.dev/cosmotech/iamguarded-charts" }
variable "harbor_chart_name" { default = "harbor" }
# variable "harbor_chart_tag" { default = "26.8.5" }
variable "harbor_chart_tag" { default = "27.0.3" }

variable "harbor_postgresql_chart_repository" { default = "oci://cgr.dev/cosmotech/iamguarded-charts" }
variable "harbor_postgresql_chart_name" { default = "postgresql" }
variable "harbor_postgresql_chart_tag" { default = "17.1.0" }
variable "harbor_postgresql_image_tag" { default = "16" }

variable "harbor_redis_chart_repository" { default = "oci://cgr.dev/cosmotech/iamguarded-charts" }
variable "harbor_redis_chart_name" { default = "redis" }
variable "harbor_redis_chart_tag" { default = "25.3.8" }
# variable "harbor_redis_chart_tag" { default = "17.3.14" }


# ingress-nginx
variable "ingressnginx_chart_repository" { default = "oci://cgr.dev/cosmotech/iamguarded-charts" }
variable "ingressnginx_chart_name" { default = "nginx-ingress-controller" }
variable "ingressnginx_chart_tag" { default = "12.0.9" }
# variable "ingressnginx_chart_repository" { default = "https://kubernetes.github.io/ingress-nginx" }
# variable "ingressnginx_chart_name" { default = "ingress-nginx" }
# variable "ingressnginx_chart_tag" { default = "4.12.3" }


# Keycloak
variable "keycloak_chart_repository" { default = "oci://cgr.dev/cosmotech/iamguarded-charts" }
variable "keycloak_chart_name" { default = "keycloak" }
variable "keycloak_chart_tag" { default = "25.3.2" }
# variable "keycloak_chart_tag" { default = "21.3.1" }

variable "keycloak_postgresql_chart_repository" { default = "oci://cgr.dev/cosmotech/iamguarded-charts" }
variable "keycloak_postgresql_chart_name" { default = "postgresql" }
variable "keycloak_postgresql_chart_tag" { default = "17.1.0" }
variable "keycloak_postgresql_image_tag" { default = "16" }


# kube-prometheus-stack
variable "prometheusstack_chart_repository" { default = "oci://cgr.dev/cosmotech/charts" }
variable "prometheusstack_chart_name" { default = "kube-prometheus-stack" }
variable "prometheusstack_chart_tag" { default = "85.1.0" }
# variable "prometheusstack_chart_repository" { default = "https://prometheus-community.github.io/helm-charts" }
# variable "prometheusstack_chart_name" { default = "kube-prometheus-stack" }
# variable "prometheusstack_chart_tag" { default = "81.6.2" }


# Superset
variable "superset_chart_repository" { default = "oci://cgr.dev/cosmotech/iamguarded-charts" }
variable "superset_chart_name" { default = "superset" }
variable "superset_chart_tag" { default = "5.0.0" }
variable "superset_postgresql_image_tag" { default = "17" }


# Global
variable "postgresql_image_repository" { default = "cosmotech/postgres-iamguarded" }
