build:
	terraform init && terraform plan && terraform apply -auto-approve
start:
	terraform apply -auto-approve
destroy:
	terraform destroy -auto-approve

unbuild:
	terraform destroy -auto-approve && rm -rf .terraform && rm .terraform.lock.hcl && rm terraform.tfstate && rm terraform.tfstate.backup