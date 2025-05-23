# Installation

To quickly start:

```bash
helm repo add chroma https://amikos-tech.github.io/chromadb-chart/
helm repo update
helm search repo chroma/
helm install chroma chroma/chromadb
```

For configuration see: https://github.com/amikos-tech/chromadb-chart


## Local Cluster

```bash
minikube start --addons=ingress -p chroma
minikube profile chroma
# install chart
```
