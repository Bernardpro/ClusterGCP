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