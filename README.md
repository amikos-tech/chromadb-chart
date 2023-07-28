# ChromaDB Vector Store Kubernetes Chart

This chart deploys a ChromaDB Vector Store cluster on a Kubernetes cluster using the Helm package manager.

## Prerequisites

- Docker
- Minikube
- Helm

> Note: Don't worry read-on for instruction how to setup of the prerequisites.


## Installing the Chart


expose the service

```bash
minikube service chroma-chromadb --url
```

## Setup Kubernetes Cluster

For this example we'll setup a Kubernetes cluster using minikube.

```bash
minikube start --addons=ingress
```