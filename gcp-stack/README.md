# Terraform ✕ Google Cloud Stack

---

## 1. Prerequisites

| Tool | Version tested | Notes |
|------|----------------|-------|
| Terraform | ≥ 1.6 .x | <https://developer.hashicorp.com/terraform/downloads> |
| Google Cloud SDK (`gcloud`) | ≥ 482 .x | <https://cloud.google.com/sdk/docs/install> |
| A GCP project with billing enabled | — | Create via `gcloud projects create ...` |

You also need a **service-account JSON key** with at least the `Editor` and `Storage Admin` roles (storage role is optional unless you add a remote backend).

---

## 2. File Layout

```
gcp-stack/
├── gcp.tf          # Main code
├── variables.tf     # Input variables
├── terraform.tfvars # Variables values
├── outputs.tf       # The ouput of terraform

```

## 3. Build the stack

```
cd gcp-stack
terraform apply
```

For init argocd you need to run the command bellow :
```
gcloud login
gcloud container clusters get-credentials php-cluster   --region europe-west1-b   --project project_id
```


## 4. Stop stack for economics usage

```
cd gcp-stack
terraform destroy -target=google_container_node_pool.nodes
```

## 5. Restart after stop

```
cd gcp-stack
terraform apply -target=google_container_node_pool.nodes
```
