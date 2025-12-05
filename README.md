![Static Badge](https://img.shields.io/badge/Cosmo%20Tech-%23FFB039?style=for-the-badge)


# Cosmo Tech shared
*Install common resources on Kubernetes clusters required by tenants*

## Requirements
- working Kubernetes cluster deployed from Cosmo Tech terraform-*provider* (like [terraform-azure](https://github.com/Cosmo-Tech/terraform-azure) for example)
- [terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)
    > If using Windows, Terraform must be accessible from PATH

## How to
* clone & open the repository
    ```
    git clone https://github.com/Cosmo-Tech/terraform-shared.git --branch <tag>
    cd terraform-shared
    ```
* deploy
    * fill terraform.tfvars variables according to your needs
    * run pre-configured script
        > ℹ️ comment/uncomment the terraform apply line at the end to get a plan without deploy anything
        * Linux
            ```
            ./_run-terraform.sh
            ```
        * Windows
            ```
            ./_run-terraform.ps1
            ```

## Known errors
* None known error for now !
    > resolution description will takes place here

## Developpers
* modules
    * *chart_cert_manager* = install Cert Manager
    * *chart_harbor* = install Harbor
    * *chart_ingress_nginx* = install Ingress Nginx
    * *chart_keycloak* = Keycloak
    * *chart_prometheus_stack* = Prometheus Stack (Prometheus/Grafana)
    * *kube_namespaces* = create namespaces for all others modules
* Terraform state
    * The state is stored beside the cluster Terraform state, in the current cloud s3/blob storage service (generally called `cosmotech-states` or `cosmotechstates`, depending on what the cloud provider allows in naming convention)
* File backend.tf
    * dynamically created at each run of `_run-terraform`
    * permit to have multi-cloud compatibility with Terraform
    * it instanciate the needed Terraform providers based on the variable `cloud_provider` from terraform.tfvars
    * this file is a workaround to avoid having unwanted variables related to cloud providers not targetted in current deployment

<br>
<br>
<br>

Made with :heart: by Cosmo Tech DevOps team