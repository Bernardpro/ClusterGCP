## 1. Rendered the manifest with helm

```
cd helm
helm template sample-app ./sample-app --values ./sample-app/values.yaml --output-dir rendered
echo "*" > ./rendered/.gitignore
```
