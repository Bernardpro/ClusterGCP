build:
	terraform init && terraform plan && terraform apply
restart:
	terraform apply 
destroy:
	terraform destroy

unbuild:
	terraform destroy && rm -rf .terraform && rm .terraform.lock.hcl && rm terraform.tfstate && rm terraform.tfstate.backup