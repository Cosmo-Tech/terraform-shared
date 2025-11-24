terraform {
  required_version = ">= 1.6.0"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.35.1"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.17.0"
    }
    kubectl = {
      source  = "alekc/kubectl"
      version = "2.1.3"
    }
    template = {
      source  = "hashicorp/template"
      version = "2.2.0"
    }
  }
}

############################################################
# Kubernetes Provider (for modules)
############################################################
provider "kubernetes" {
  host                   = data.terraform_remote_state.terraform_cluster.outputs.cluster_endpoint
  client_certificate     = base64decode(data.terraform_remote_state.terraform_cluster.outputs.cluster_client_certificate)
  client_key             = base64decode(data.terraform_remote_state.terraform_cluster.outputs.cluster_client_key)
  cluster_ca_certificate = base64decode(data.terraform_remote_state.terraform_cluster.outputs.cluster_ca_certificate)
}

############################################################
# Helm Provider
############################################################
provider "helm" {
  kubernetes {
    host                   = data.terraform_remote_state.terraform_cluster.outputs.cluster_endpoint
    client_certificate     = base64decode(data.terraform_remote_state.terraform_cluster.outputs.cluster_client_certificate)
    client_key             = base64decode(data.terraform_remote_state.terraform_cluster.outputs.cluster_client_key)
    cluster_ca_certificate = base64decode(data.terraform_remote_state.terraform_cluster.outputs.cluster_ca_certificate)
  }
}

############################################################
# Kubectl Provider
############################################################
provider "kubectl" {
  host                   = data.terraform_remote_state.terraform_cluster.outputs.cluster_endpoint
  client_certificate     = base64decode(data.terraform_remote_state.terraform_cluster.outputs.cluster_client_certificate)
  client_key             = base64decode(data.terraform_remote_state.terraform_cluster.outputs.cluster_client_key)
  cluster_ca_certificate = base64decode(data.terraform_remote_state.terraform_cluster.outputs.cluster_ca_certificate)
}


############################################################
# Kubernetes Provider (for resource management)
############################################################
# provider "kubernetes" {
#   host                   = "https://${data.terraform_remote_state.terraform_cluster.outputs.cluster_endpoint}"
#   cluster_ca_certificate = base64decode(data.terraform_remote_state.terraform_cluster.outputs.cluster_ca_certificate)
#   token                  = data.google_client_config.current.access_token
# }

# ############################################################
# # Helm Provider (for Helm releases)
# ############################################################
# provider "helm" {
#   kubernetes {
#     host                   = "https://${data.terraform_remote_state.terraform_cluster.outputs.cluster_endpoint}"
#     cluster_ca_certificate = base64decode(data.terraform_remote_state.terraform_cluster.outputs.cluster_ca_certificate)
#     token                  = data.google_client_config.current.access_token
#   }
# }

# ############################################################
# # Kubectl Provider (for manifests & CRDs)
# ############################################################
# provider "kubectl" {
#   host                   = "https://${data.terraform_remote_state.terraform_cluster.outputs.cluster_endpoint}"
#   cluster_ca_certificate = base64decode(data.terraform_remote_state.terraform_cluster.outputs.cluster_ca_certificate)
#   token                  = data.google_client_config.current.access_token
# }
