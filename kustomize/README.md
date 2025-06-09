## 1. Start project in dev mode

```
cd T-CLO-902-LYO_1
kustomize build kustomize/overlays/dev --enable-helm | kubectl apply -f -
```

## 2. Start project in prod mode

```
cd T-CLO-902-LYO_1
kustomize build kustomize/overlays/prod --enable-helm | kubectl apply -f -
```

## 3. Describe the deployment

```
kubectl get all
kubectl describe deployment sample-app
```
