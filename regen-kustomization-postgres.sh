#!/bin/bash

BASE_DIR=~/kustomize/postgres
KUSTOM_FILE="$BASE_DIR/kustomization.yaml"
SEARCH_DIR="$BASE_DIR/rendered/postgresql/templates"

echo "🛠 Génération d'un nouveau kustomization.yaml..."
echo "namespace: postgres" > "$KUSTOM_FILE"
echo "resources:" >> "$KUSTOM_FILE"

# Ajouter tous les fichiers .yaml trouvés
find "$SEARCH_DIR" -type f -name "*.yaml" | sort | while read -r file; do
  # Convertir en chemin relatif depuis BASE_DIR
  rel_path="${file#$BASE_DIR/}"
  echo "  - $rel_path" >> "$KUSTOM_FILE"
done

echo "✅ Fichier $KUSTOM_FILE généré avec succès !"
