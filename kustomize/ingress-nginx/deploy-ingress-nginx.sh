#!/bin/bash

# Nettoyage du PATH WSL (évite les "Program Files/Microsoft")
export PATH="/usr/local/bin:/usr/bin:/bin:/snap/bin"

# Vérifie si Helm est accessible
if ! command -v helm &> /dev/null; then
    echo "❌ Helm non détecté. Vérifie son installation."
    exit 1
fi

echo "✅ Helm trouvé : $(helm version --short)"

# Vérifie si Kustomize est accessible
if ! command -v kustomize &> /dev/null; then
    echo "❌ Kustomize non détecté. Installe-le avec: sudo snap install kustomize"
    exit 1
fi

echo "✅ Kustomize trouvé : $(kustomize version --short)"

# Génère les manifestes
echo "🛠️  Génération des manifestes avec Kustomize + Helm..."
kustomize build . --enable-helm > output.yaml

if [ $? -ne 0 ]; then
    echo "❌ Erreur lors du build Kustomize"
    exit 1
fi

# Applique sur le cluster
echo "🚀 Application sur le cluster GKE..."
kubectl apply -f output.yaml

# Vérifie
echo "✅ Déploiement terminé. Services NGINX :"
kubectl get svc -n ingress-nginx

