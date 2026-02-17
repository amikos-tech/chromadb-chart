# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Helm chart repository for deploying ChromaDB (a vector database) on Kubernetes. The chart is maintained by Amikos Tech and provides a single-node Chroma database deployment with support for various configuration options including authentication, persistence, and observability.

## Key Commands

### Helm Chart Development

```bash
# Lint the chart locally
make lint
# or directly:
helm lint charts/chromadb-chart

# Install the chart for local testing (requires Kubernetes cluster)
helm install chromadb ./charts/chromadb-chart --set chromadb.allowReset=true

# Run Helm tests after installation
helm test chromadb

# Package the chart
helm package charts/chromadb-chart

# Update chart dependencies
helm dependency update charts/chromadb-chart
```

### Testing

```bash
# Run Python integration tests (requires ChromaDB instance running)
python tests/test_chroma.py

# Run Helm chart tests in Kubernetes
helm test chromadb

# GitHub Actions integration tests run on:
# - Kubernetes versions: 1.23.0, 1.33.1
# - Chroma versions: 0.6.3, 1.0.10
```

### Local Development with Minikube

```bash
# Setup Minikube cluster with ingress
minikube start --addons=ingress -p chroma
minikube profile chroma

# Forward service to localhost
minikube service chromadb --url
```

## Architecture & Structure

### Chart Components

The Helm chart (`charts/chromadb-chart/`) contains:

- **StatefulSet Deployment**: Main ChromaDB application deployed as a StatefulSet with persistent storage
- **Service**: ClusterIP service exposing ChromaDB API on port 8000
- **ConfigMap**: Configuration for ChromaDB settings including auth, logging, and telemetry
- **Secret**: Auto-generated or custom authentication credentials (token/basic auth)
- **PersistentVolumeClaim**: Storage for ChromaDB data (configurable size and storage class)
- **Ingress**: Optional ingress for external access
- **Test Jobs**: Kubernetes Jobs for testing API connectivity and authentication

### Key Configuration Points

The chart supports multiple ChromaDB versions from 0.4.3 to 1.0.x with version-specific features:

- **Authentication**: Supported in versions < 1.0.0 (token auth from 0.4.8+, basic auth from 0.4.7+)
- **Logging Configuration**: Custom log levels and config maps (versions < 1.0.0)
- **Cache Management**: LRU cache policy configuration (versions < 1.0.0)
- **CORS Configuration**: List-based CORS origins (wildcard not supported in 1.0.0+)
- **Telemetry**: OTEL telemetry support with configurable endpoints

### GitHub Workflows

- **Lint on PR** (`.github/workflows/lint.yml`): Validates chart syntax on pull requests
- **Integration Tests** (`.github/workflows/integration-test.yml`): Tests chart installation across multiple Kubernetes and ChromaDB versions
- **Release** (`.github/workflows/release.yml`): Handles chart packaging and publishing to GitHub Pages

## Important Notes

- Default ChromaDB version is 1.0.10 (as of chart version 0.1.24)
- Authentication is NOT supported in ChromaDB 1.0.x - use network-level security or API gateway
- Data persistence is enabled by default at `/data` directory
- Anonymous telemetry is disabled by default for privacy
- The chart uses ghcr.io/chroma-core/chroma as the default image repository