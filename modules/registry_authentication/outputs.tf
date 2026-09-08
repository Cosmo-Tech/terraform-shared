## YAML bloc ready to use in Helm Charts values.yaml
## Example:
## - name: regsitry-auth-example1
## - name: regsitry-auth-example2
## - name: regsitry-auth-example3
output "image_registry_auth_secret_list" {
  value = yamlencode(distinct([
    for item in local.secret_copies : {
      name = item.secret
    }
  ]))
}
