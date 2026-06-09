![Static Badge](https://img.shields.io/badge/Cosmo%20Tech-%23FFB039?style=for-the-badge) ![Static Badge](https://img.shields.io/badge/Shared-%23dbdbdb?style=for-the-badge)


# Cosmo Tech shared
*Install common resources on Kubernetes clusters required by tenants*

## Requirements
* working Kubernetes cluster deployed from Cosmo Tech terraform-*provider* (like [terraform-azure](https://github.com/Cosmo-Tech/terraform-azure) for example)
* [terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)
    > If using Windows, Terraform must be accessible from PATH
* [docker](https://docs.docker.com/engine/install)
* Github account, [authenticated for ghcr.io usage](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)
* A Cosmo Tech image registry username/password (provided by a Cosmo Tech administrator)

## How to
* clone & open the repository
    ```
    git clone https://github.com/Cosmo-Tech/terraform-shared.git --branch <tag>
    cd terraform-shared
    ```
* deploy
    * fill `terraform.tfvars` variables according to your needs
    * first deployment?
        * if no, go to the next step
        * if yes, the module will ask the credentials of your private Image Registry (containing all the images required for the deployment)
            > your administrator will be able to provide username/password
            * *username*
                ```
                export TF_VAR_image_registry_username=USERNAME
                ```
            * *password*
                ```
                export TF_VAR_image_registry_password=PASSWORD
                ```
            * *[optional] the default Image Registry of Cosmo Tech is setted but you can override it*
                ```
                export TF_VAR_image_registry='example.dev'
                ```
    * run pre-configured script
        * plan
            > get an execution plan to preview the changes without applying
            * Linux
                ```
                ./_run-terraform.sh
                ```
            * Windows
                ```
                ./_run-terraform.ps1
                ```
        * apply
            > executes the operations proposed in the plan
            * Linux
                ```
                ./_run-terraform.sh --apply
                ```
            * Windows
                ```
                ./_run-terraform.ps1 --apply
                ```

## Known errors
* TLS certificate: 'Kubernetes Ingress Controller Fake Certificate' default certificate is still used
    > When using cert-manager, the rate limit imposed by Let's Encrypt has maybe be reached. It happen when too many deployments were done in a short time. Use the following commands to verify if the issue is about Let's Encrypt rate limit: \
    > `kubectl get certificate -A` \
    > `kubectl -n NAMESPACE_LISTED_FROM_PREVIOUS_COMMAND describe certificate letsencrypt-prod`
* On-premise DNS: "address could not be found"
    > A DNS record must be manually added since Terraform modules can't access private DNS servers. \
    > Ensure an existing DNS record is pointing to the Kubernetes cluster IP.

## Developpers
* modules
    * **terraform-shared**
        * *chart_cert_manager* = install Cert Manager and a Let's Encrypt certificate
        * *chart_harbor* = install Harbor
        * *chart_ingress_nginx* = install Ingress Nginx
        * *chart_keycloak* = install Keycloak
        * *chart_prometheus_stack* = install Prometheus Stack (Prometheus/Grafana)
        * *chart_superset* = install Superset
        * *kube_namespaces* = create namespaces & their default configuration for all others modules
        * *kube_storageclass* = create a custom storage class
        * *registry_authentication* = create a root secret to authenticate with Image Registry
        * *workload_scheduler* = create automatic scheduler to stop/start the cluster at a given time
* Terraform state
    * The state is stored beside the cluster Terraform state, in the current cloud s3/blob storage service (generally called `cosmotech-states` or `csmstates<id>`, depending on what the cloud provider allows in naming convention)
* Scripts **_run-terraform.***
    * Automatically detect hosting target (cloud provider name, on-premise...), and adapt the Terraform module to work with it
    * Terraform modules can work without the scripts, but will require some additional manual steps.
* File **target.tf**
    * Allow to have multi-cloud compatibility with Terraform
    * This file is dynamically created at each run of `_run-terraform`
    * It instanciates the needed Terraform configuration based on the variable `cloud_provider` from terraform.tfvars
        > `$TEMPLATE_` variables in files stored in `targets/` are automatically replaced with values from `terraform.tfvars`
    * This file is a workaround to avoid having unwanted variables related to cloud providers not targetted in current deployment
* File **variables_defaults**
    * contains all the defaults configurations of the module
    * all artefacts versions are tagged in this file
    * everything is this file can be customized from TF_VAR_variable, CLI arguments or terraform.tfvars

<br>
<br>
<br>

Made with :heart: by Cosmo Tech DevOps team