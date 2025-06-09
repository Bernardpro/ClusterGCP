## 1. Start project in dev mode

```
cd kustomize
kubectl apply -k kustomize/overlays/dev
```

## 2. Start project in prod mode

```
cd kustomize
kubectl apply -k kustomize/overlays/prod
```

## 3. Describe the deployment

```
kubectl get all
kubectl describe deployment sample-app
```
