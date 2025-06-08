#!/bin/bash

set -e

# 1. Répertoire de travail
BASE_DIR=~/kustomize/postgres
VALUES_FILE=$BASE_DIR/postgres-values.yaml
RENDER_DIR=$BASE_DIR/rendered

echo "📁 Création du dossier $BASE_DIR..."
mkdir -p "$RENDER_DIR"

# 2. Ajouter le repo Helm officiel Bitnami
echo "📦 Ajout du repo Helm Bitnami..."
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# 3. Créer le fichier values.yaml personnalisé
echo "📝 Création du fichier values.yaml..."
cat <<EOF > "$VALUES_FILE"
auth:
  username: myuser
  password: mypassword
  database: mydatabase

primary:
  persistence:
    enabled: true
    size: 1Gi
    storageClass: standard
EOF

# 4. Générer les manifests avec Helm template
echo "📄 Génération des manifests Kubernetes avec Helm..."
helm template my-postgres bitnami/postgresql \
  --namespace postgres \
  -f "$VALUES_FILE" \
  --output-dir "$RENDER_DIR"

# 5. Créer un kustomization.yaml
echo "🛠️ Création du fichier kustomization.yaml..."
cat <<EOF > "$BASE_DIR/kustomization.yaml"
namespace: postgres
resources:
  - rendered/bitnami/postgresql/templates/
EOF

echo "✅ Tout est prêt dans : $BASE_DIR"
echo "▶️ Tu peux maintenant faire :"
echo "   kubectl create namespace postgres"
echo "   kubectl apply -k $BASE_DIR"
