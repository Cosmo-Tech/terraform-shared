config {
  call_module_type = "none" # cannot select another type due to target.tf which is created from _run-terraform.sh
}

rule "terraform_unused_declarations" { enabled = false } # variables_default.tf is full of unused variables, depending on which tenant type is selected
rule "terraform_standard_module_structure" { enabled = false } # target.tf, variables_default.tf, tenant_recipes.tf = non standard, but we still need them
rule "terraform_required_providers" { enabled = false } # providers in sub modules doesn't have a fixed version, thanks to DRY principle, every versions are tagged in the root providers.tf 
rule "terraform_required_version" { enabled = false } # providers in sub modules doesn't have a fixed version, thanks to DRY principle, every versions are tagged in the root providers.tf 
rule "terraform_typed_variables" { enabled = false } # variables_default.tf doesn't have types because it's an human-readable file
rule "terraform_module_pinned_source" { enabled = false } # storage modules are based on main branches

rule "terraform_deprecated_interpolation" { enabled = true }
