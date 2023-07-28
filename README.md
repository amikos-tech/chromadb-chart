# ChromaDB Vector Store Kubernetes Chart

This chart deploys a ChromaDB Vector Store cluster on a Kubernetes cluster using the Helm package manager.

## Prerequisites

> Note: These prerequisites are necessary for local testing. If you have a Kubernetes cluster already setup you can skip

- Docker
- Minikube
- Helm

## Notes on the Chart image

To make it possible and efficient to run chroma in Kubernetes we take the chroma base image (ghcr.io/chroma-core/chroma:<tag>) and we improve on it by:

- Removing unnecessary files from the `/chroma` dir
- Improving on the `docker_entrypoint.sh` script to make it more suitable for running in Kubernetes

Checkout `image/` dir for more details.

## Installing the Chart

Setup the helm repo:

```bash
helm repo add chroma https://amikos-tech.github.io/chromadb-chart/
helm repo update
helm search repo chroma
```

Update the `values.yaml` file to match your environment.

```bash
helm install chroma chroma/chromadb -f values.yaml
```

Example `values.yaml` file:

```yaml
chromadb:
  allowReset: "true"
```

Alternatively you can specify each parameter using the `--set key=value[,key=value]` argument to `helm install`.

```bash
helm install chroma chroma/chromadb --set chromadb.allowReset="true"
```

## Chart Configuration Values

| Key                               | Type    | Default                               | Description                                                                                                                                                                        |
|-----------------------------------|---------|---------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `chromadb.allowReset`             | boolean | `false`                               | Allows resetting the index (delete all data)                                                                                                                                       |
| `chromadb.isPersistent`           | boolean | `true`                                | A flag to control whether data is persisted                                                                                                                                        |
| `chromadb.persistDirectory`       | string  | `/index_data`                         | The location to store the index data. This configure both chromadb and underlying persistent volume                                                                                |
| `chromadb.logConfigFileLocation`  | string  | `config/log_config.yaml`              | The location of the log config file. By default the on in the chart's config/ dir is taken                                                                                         |
| `chromadb.anonymizedTelemetry`    | boolean | `false`                               | The flag to send anonymized stats using posthog. By default this is enabled in the chromadb however for user's privacy we have disabled it so it is opt-in                         |
| `chromadb.corsAllowOrigins`       | list    | `- "*"`                               | The CORS config. By default we allow all (possibly a security concern)                                                                                                             |
| `chromadb.apiImpl`                | string  | `- "chromadb.api.segment.SegmentAPI"` | The default API impl. It uses SegmentAPI however FastAPI is also available. Note: FastAPI seems to be bugging so we discourage users to use it in releases prior or equal to 0.4.3 |
| `chromadb.serverHost`             | string  | `0.0.0.0`                             | The API server host.                                                                                                                                                               |
| `chromadb.serverHttpPort`         | int     | `8000`                                | The API server port.                                                                                                                                                               |
| `chromadb.dataVolumeSize`         | string  | `1Gi`                                 | The data volume size.                                                                                                                                                              |
| `chromadb.dataVolumeStorageClass` | striung | `standard`                            | The storage class                                                                                                                                                                  |

## Verifying installation

```bash
minikube service chroma-chromadb --url
```

## Setup Kubernetes Cluster

For this example we'll set up a Kubernetes cluster using minikube.

```bash
minikube start --addons=ingress
```

## References

- Helm install: https://helm.sh/docs/intro/install/
- Minikube install: https://minikube.sigs.k8s.io/docs/start/
- ChromaDB: https://docs.trychroma.com/getting-started