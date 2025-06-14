# Terraform ✕ Google Cloud Stack

---

## 1. Prerequisites

| Tool | Version tested | Notes |
|------|----------------|-------|
| Terraform | ≥ 1.6 .x | <https://developer.hashicorp.com/terraform/downloads> |
| Google Cloud SDK (`gcloud`) | ≥ 482 .x | <https://cloud.google.com/sdk/docs/install> |
| A GCP project with billing enabled | — | Create via `gcloud projects create ...` |
| Install uv | ≥ 0.6.3 | <https://docs.astral.sh/uv/getting-started/installation> via `uv venv` |
| Init python dependencies | — | Init via `uv venv` |



You also need a **service-account JSON key** with at least the `Editor`, `Cloud Tunnel API` and `Storage Admin` roles (storage role is optional unless you add a remote backend).

Recommandations :
Download your json key credentials file with the path : /gcp-stack/credentials/terraform-sa.json

In last run the commands below for ssh :

```
ssh-keygen -t rsa -b 4096 -f /gcp-stack/credentials/ssh-key
```

```
gcloud auth login
gcloud compute project-info add-metadata --project=YOUR_PROJECT_ID \
  --metadata-from-file ssh-keys=gcp-stack/credentials/ssh-key.pub
```
---

## 2. File Layout

```
gcp-stack/
├── gcp.tf          # Main code
├── variables.tf     # Input variables
├── terraform.tfvars # Variables values (Update it for your configuration) 
├── outputs.tf       # The ouput of terraform

```

## 3. Build the stack

```
cd gcp-stack
terraform init
terraform plan
terraform apply
```

## 4. Stop stack for economics usage

```
cd gcp-stack
terraform destroy 
```

## 5. Restart after stop

```
cd gcp-stack
terraform apply 
```

## 6. Fecth the credentials for argocd :

```
kubectl get svc -A | grep LoadBalancer
```

```
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo
```
