# ChromaDB Vector Store Kubernetes Chart

This chart deploys a ChromaDB Vector Store cluster on a Kubernetes cluster using the Helm package manager.

## Roadmap

- [ ] Security - the ability to secure chroma API with TLS and OIDC <- PoC completed waiting to be merged in the main
  repo
- [ ] Backup and restore - the ability to back up and restore the index data
- [ ] Monitoring - the ability to monitor the cluster using Prometheus and Grafana

## Prerequisites

> Note: These prerequisites are necessary for local testing. If you have a Kubernetes cluster already setup you can skip

- Docker
- Minikube
- Helm

## Notes on the Chart image

To make it possible and efficient to run chroma in Kubernetes we take the chroma base image (
ghcr.io/chroma-core/chroma:<tag>) and we improve on it by:

- Removing unnecessary files from the `/chroma` dir
- Improving on the `docker_entrypoint.sh` script to make it more suitable for running in Kubernetes

Checkout `image/` dir for more details.

## Installing the Chart

Setup the helm repo:

```bash
helm repo add chroma https://amikos-tech.github.io/chromadb-chart/
helm repo update
helm search repo chroma/
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
| `chromadb.apiVersion`             | string  | `0.4.6`                               | The ChromaDB version. Supported version `0.4.3` and `0.4.4`                                                                                                                        |
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
| `chromadb.dataVolumeStorageClass` | string  | `standard`                            | The storage class                                                                                                                                                                  |
| `chromadb.auth.enabled`           | boolean | `true`                                | A flag to enable/disable authentication in Chroma                                                                                                                                  |
| `chromadb.auth.type`              | string  | `token`                                   | Type of auth. Currently "token" (apiVersion>=0.4.8) and "basic" (apiVersion>=0.4.7) are supported.                                                                   |

## Verifying installation

```bash
minikube service chroma-chromadb --url
```

## Building the Docker image

```bash
docker build --no-cache -t <image:tag> -f image/Dockerfile .
docker push <image:tag>
```

## Setup Kubernetes Cluster

For this example we'll set up a Kubernetes cluster using minikube.

```bash
minikube start --addons=ingress -p chroma #create a simple minikube cluster with ingress addon
minikube profile chroma #select chroma profile in minikube as active for kubectl commands
```

## Chroma Authentication

> Note: Token auth is enabled by default

By default, the chart will use a `chromadb-auth` secret in Chroma's namespace to authenticate requests. This secret is
generated at install time.

Chroma authentication is supported for the following API versions:
- basic >= 0.4.7
- token >= 0.4.8

> Note: Using auth parameters with lower version will result in auth parameters being ignored.

### Token Auth

Token Auth works with two types of headers that can be configured via `chromadb.auth.token.tokenHeader`:
- `AUTHORIZATION` (default) - the clients are expected to pass `Authorization: Brearer <token>` header
- `X-CHROMA-TOKEN` - the clients are expected to pass `X-Chroma-Token: <token>` header

Get the token:
    
```bash
CHROMA_TOKEN=$(kubectl --namespace default get secret chromadb-auth -o jsonpath="{.data.token}" | base64 --decode)
CHROMA_HEADER_NAME=$(kubectl --namespace default get secret chromadb-auth -o jsonpath="{.data.header}" | base64 --decode)
```

>Note: The above examples assume `default` namespace is used for Chroma deployment.

Test the token:

```bash
curl -v http://localhost:8000/api/v1/collections -H "${CHROMA_HEADER_NAME}: ${CHROMA_TOKEN}"
```

> Note: The above `curl` assumes a localhost forwarding is made to port 8000

### Basic Auth

Get auth credentials:

```bash
CHROMA_BASIC_AUTH_USERNAME=$(kubectl --namespace default get secret chromadb-auth -o jsonpath="{.data.username}" | base64 --decode)
CHROMA_BASIC_AUTH_PASSWORD=$(kubectl --namespace default get secret chromadb-auth -o jsonpath="{.data.password}" | base64 --decode)
```

>Note: The above examples assume `default` namespace is used for Chroma deployment.

Test the token:

```bash
curl -v http://localhost:8000/api/v1/collections -u "${CHROMA_BASIC_AUTH_USERNAME}:${CHROMA_BASIC_AUTH_PASSWORD}" 
```

> Note: The above `curl` assumes a localhost forwarding is made to port 8000

## References

- Helm install: https://helm.sh/docs/intro/install/
- Minikube install: https://minikube.sigs.k8s.io/docs/start/
- ChromaDB: https://docs.trychroma.com/getting-started