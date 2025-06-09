## 1. Build template helm

### Prérequis

Run terraform in the gcp-stack folder. Follow the README file instructions.

---

For deployment use this commande below in GKE console.

### 1.1 Generate the manifests with helm

Change the mode variable for developement or producitons purpose.


```
mode=dev
cd kustomize/base
helm template sample-app ../../helm/sample-app --values ../overlays/${mode}/values-${mode}.yaml --output-dir rendered
echo "*" > ./rendered/.gitignore
```

### 1.2 Add kustomization config file to the rendered charts
```
cat <<EOF > ./rendered/sample-app/templates/kustomization.yaml
resources:
  - deployment.yaml
  - service.yaml
  - ingress.yaml
  - secret.yaml
  - mysql-deployment.yaml
  - mysql-service.yaml
  - mysql-pvc.yaml
EOF
```

## 2. Start project in dev mode

```
cd T-CLO-902-LYO_1
kustomize build kustomize/overlays/dev --enable-helm | kubectl apply -f -
```

## 2.bis Start project in prod mode

```
cd T-CLO-902-LYO_1
kustomize build kustomize/overlays/prod --enable-helm | kubectl apply -f -
```

## 3. Describe the deployment

```
kubectl get all
kubectl describe deployment sample-app
```


## 4. Deploy ingress 

# 4.1 Install depencies for ingress-nginx 

```
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --create-namespace \
  --namespace ingress-nginx \
  --set controller.service.type=LoadBalancer \
  --set controller.admissionWebhooks.enabled=false
```

# 4.2 Get the http IP adress

```
kubectl get ingress
```

