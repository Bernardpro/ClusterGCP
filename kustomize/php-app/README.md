# 📦 Déploiement de l'application PHP via NGINX Ingress (GKE)

Ce dossier contient les manifests Kustomize pour déployer une application PHP simple, exposée via un Ingress NGINX en **Load Balancer interne GCP**.

---

## 📁 Structure des fichiers

- `deployment.yaml` – Déploiement de l'app PHP avec volume `configMap` monté.
- `service.yaml` – Service ClusterIP pour exposer l'app en interne.
- `ingress.yaml` – Ingress NGINX sur `php.gke.local`.
- `configmap.yaml` – Contient le code source (`index.php`).
- `kustomization.yaml` – Assemble tous les fichiers ci-dessus.

---

## 🚀 Déploiement manuel

> Prérequis : avoir un cluster GKE actif + NGINX Ingress installé avec Internal LoadBalancer

### 1. Se positionner dans le dossier

```bash
cd ~/kustomize/php-app
