# Kubernetes Chart for Chroma AI application database

[![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/chromadb-helm)](https://artifacthub.io/packages/search?repo=chromadb-helm)

This chart deploys a single-node Chroma database on a Kubernetes cluster using the Helm package manager.

> [!TIP]
> Deploying and managing multiple Chroma nodes support will arrive with
> the [Chroma single-node Operator](https://github.com/amikos-tech/chromadb-operator).


> [!WARNING]
> Chroma 1.0.0-1.0.10 does not yet support authentication and authorization. While the feature is added, we advise using
> network-level security controls, deploying behind a secure API gateway, or upgrading to a newer version if your use
> case
> requires authentication.

## Roadmap

- [ ] `Work in progress` Security - the ability to secure chroma API with TLS
- [ ] `Work in progress` Backup and restore - the ability to back up and restore the index data
- [ ] `Work in progress` Observability - the ability to monitor the cluster using Prometheus and Grafana

## Prerequisites

> [!NOTE]
> Note: These prerequisites are necessary for local testing. If you have a Kubernetes cluster already setup you can skip

- Docker
- Minikube
- Helm

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

| Key                                                 | Type    | Default                               | Description                                                                                                                                                                                                                                                                                                |
|-----------------------------------------------------|---------|---------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `chromadb.apiVersion`                               | string  | `1.0.10` (Chart app version)          | The ChromaDB version. Supported version `0.4.3` - `1.0.x`                                                                                                                                                                                                                                                  |
| `chromadb.allowReset`                               | boolean | `false`                               | Allows resetting the index (delete all data)                                                                                                                                                                                                                                                               |
| `chromadb.isPersistent`                             | boolean | `true`                                | A flag to control whether data is persisted                                                                                                                                                                                                                                                                |
| `chromadb.persistDirectory`                         | string  | `/data`                               | The location to store the index data. This configure both chromadb and underlying persistent volume                                                                                                                                                                                                        |
| `chromadb.anonymizedTelemetry`                      | boolean | `false`                               | The flag to send anonymized stats using posthog. By default this is enabled in the chromadb however for user's privacy we have disabled it so it is opt-in                                                                                                                                                 |
| `chromadb.corsAllowOrigins`                         | list    | N/A                                   | The CORS config. Wildcard ["*"] is not supported in version 1.0.0 or later.                                                                                                                                                                                                                                |
| `chromadb.apiImpl`                                  | string  | `- "chromadb.api.segment.SegmentAPI"` | The default API impl. It uses SegmentAPI however FastAPI is also available. Note: FastAPI seems to be bugging so we discourage users to use it in releases prior or equal to 0.4.3 Deprecated in since 0.1.23 (will be removed in 0.2.0)                                                                   |
| `chromadb.serverHost`                               | string  | `0.0.0.0`                             | The API server host.                                                                                                                                                                                                                                                                                       |
| `chromadb.serverHttpPort`                           | int     | `8000`                                | The API server port.                                                                                                                                                                                                                                                                                       |
| `chromadb.data.volumeSize`                          | string  | `1Gi`                                 | The data volume size.                                                                                                                                                                                                                                                                                      |
| `chromadb.data.storageClass`                        | string  | `null` (default storage class)        | The storage class                                                                                                                                                                                                                                                                                          |
| `chromadb.data.accessModes`                         | [string]  | `[ "ReadWriteOnce" ]`                       | The volume access mode.                                                                                                                                                                                                                                                                                    |
| `chromadb.data.retentionPolicyOnDelete`             | string  | `"Delete"`                            | The retention policy on removal. By default the PVC will be remove when Chroma chart is uninstalled. If you wish to keep it set this value to `Retain`.                                                                                                                                                    |
| `chromadb.auth.enabled`                             | boolean | `true`                                | A flag to enable/disable authentication in Chroma. **Note**: This is not supported in Chroma version 1.0.0 or later.                                                                                                                                                                                       |
| `chromadb.auth.type`                                | string  | `token`                               | Type of auth. Currently "token" (apiVersion>=0.4.8) and "basic" (apiVersion>=0.4.7) are supported. **Note**: This is not supported in Chroma version 1.0.0 or later.                                                                                                                                       |
| `chromadb.auth.token.headerType`                    | string  | `Authorization`                       | The header type for the token. Possible values: `Authorization` or `X-Chroma-Token` (also works with `X_CHROMA_TOKEN`). **Note**: This is not supported in Chroma version 1.0.0 or later.                                                                                                                  |
| `chromadb.auth.existingSecret`                      | string  | `""`                                  | Name of an [existing secret](#using-customexisting-secret) with the auth credentials. For token auth the secret should have `token` data and for basic auth the secret should have `username` and `password` data. **Note**: This is not supported in Chroma version 1.0.0 or later.                       |
| `image.repository`                                  | string  | `ghcr.io/chroma-core/chroma`          | The repository of the image.                                                                                                                                                                                                                                                                               |
| `chromadb.logging.root`                             | string  | `INFO`                                | The root logging level. **Note**: This is not supported in Chroma version 1.0.0 or later.                                                                                                                                                                                                                  |
| `chromadb.logging.chromadb`                         | string  | `DEBUG`                               | The chromadb logging level. **Note**: This is not supported in Chroma version 1.0.0 or later.                                                                                                                                                                                                              |
| `chromadb.logging.uvicorn`                          | string  | `INFO`                                | The uvicorn logging level. **Note**: This is not supported in Chroma version 1.0.0 or later.                                                                                                                                                                                                               |
| `chromadb.logConfigMap`                             | string  | `null`                                | The name of the config map with the logging configuration. If not set, the default logging configuration will be used. By default the chart ships with `log-config` config map, but you can provide your own logging configuration map.  **Note**: This is not supported in Chroma version 1.0.0 or later. |
| `chromadb.maintenance.collection_cache_policy`      | string  | `null`                                | The collection cache policy. Possible values: null or "LRU". Read more [here](https://cookbook.chromadb.dev/strategies/memory-management/#lru-cache-strategy). **Note**: This is not supported in Chroma version 1.0.0 or later.                                                                           |
| `chromadb.maintenance.collection_cache_limit_bytes` | int     | `1000000000`                          | The collection cache limit in bytes. **Note**: This is not supported in Chroma version 1.0.0 or later.                                                                                                                                                                                                     |
| `chromadb.maxPayloadSizeBytes`                      | int     | `41943040`                            | The size in bytes of  the maximum payload that can be sent to Chroma. This is supported in v1.0.0 or later.                                                                                                                                                                                                |
| `chromadb.telemetry.enabled`                        | boolean | `false`                               | Enables chroma to send OTEL telemetry                                                                                                                                                                                                                                                                      |
| `chromadb.telemetry.endpoint`                       | string  | ``                                    | OTEL collector endpoint e.g. "http://otel-collector:4317"                                                                                                                                                                                                                                                  |
| `chromadb.telemetry.serviceName`                    | string  | `chroma`                              | The service name that will show up in traces.                                                                                                                                                                                                                                                              |

## Nginx Configuration Values


| Key                                         | Type    | Default                        | Description                                                                                |
| ------------------------------------------- | ------- | ------------------------------ | ------------------------------------------------------------------------------------------ |
| `nginx.enabled`                             | boolean | `false`                        | Enable / disable the NGINX proxy sidecar.                                                  |
| `nginx.image`                               | string  | `docker.io/library/nginx:1.23` | NGINX container image (registry + repository + tag).                                       |
| `nginx.imagePullPolicy`                     | string  | `Always`                       | Image pull policy.                                                                         |
| `nginx.resources`                           | object  | `{}`                           | Resource requests/limits for the NGINX container.                                          |
| `nginx.containerPorts.http`                 | int     | `443`                          | Port exposed by the NGINX container (HTTP or HTTPS depending on `tls.enabled`).            |
| `nginx.tls.enabled`                         | boolean | `true`                         | Enable TLS termination inside the NGINX container (expects `chromadb-tls` secret mounted). |
| `nginx.containerSecurityContext.enabled`    | boolean | `false`                        | Enable custom security context for the NGINX container.                                    |
| `nginx.containerSecurityContext.secContext` | object  | see values.yaml                | SecurityContext spec applied if `containerSecurityContext.enabled` is `true`.              |

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

> [!NOTE]
> Token auth is enabled by default. **Not supported in Chroma 1.0.x.**

By default, the chart will use a `chromadb-auth` secret in Chroma's namespace to authenticate requests. This secret is
generated at install time.

Chroma authentication is supported for the following API versions:

- `basic` >= 0.4.7
- `token` >= 0.4.8

> [!NOTE]
> Using auth parameters with lower version will result in auth parameters being ignored.

### Token Auth

Token Auth works with two types of headers that can be configured via `chromadb.auth.token.tokenHeader`:

- `AUTHORIZATION` (default) - the clients are expected to pass `Authorization: Bearer <token>` header
- `X-CHROMA-TOKEN` (also works with `X_CHROMA_TOKEN`) - the clients are expected to pass `X-Chroma-Token: <token>`
  header

> [!NOTE]
> The header type is case-insensitive.

Get the token:

```bash
export CHROMA_TOKEN=$(kubectl --namespace default get secret chromadb-auth -o jsonpath="{.data.token}" | base64 --decode)
export CHROMA_HEADER_NAME=$(kubectl --namespace default get configmap chroma-chromadb-token-auth-config -o jsonpath="{.data.CHROMA_AUTH_TOKEN_TRANSPORT_HEADER}")
```

> [!NOTE]
> Note: The above examples assume `default` namespace is used for Chroma deployment.

Test the token:

```bash
curl -v http://localhost:8000/api/v1/collections -H "${CHROMA_HEADER_NAME}: Bearer ${CHROMA_TOKEN}"
```

> [!NOTE]
> The above `curl` assumes a localhost forwarding is made to port 8000
> If auth header is `AUTHORIZATION` then add `Bearer` prefix to the token when using curl.

### Basic Auth

Get auth credentials:

```bash
CHROMA_BASIC_AUTH_USERNAME=$(kubectl --namespace default get secret chromadb-auth -o jsonpath="{.data.username}" | base64 --decode)
CHROMA_BASIC_AUTH_PASSWORD=$(kubectl --namespace default get secret chromadb-auth -o jsonpath="{.data.password}" | base64 --decode)
```

> [!NOTE]
> The above examples assume `default` namespace is used for Chroma deployment.

Test the token:

```bash
curl -v http://localhost:8000/api/v1/collections -u "${CHROMA_BASIC_AUTH_USERNAME}:${CHROMA_BASIC_AUTH_PASSWORD}"
curl -v http://localhost:8000/api/v1/collections -u "${CHROMA_BASIC_AUTH_USERNAME}:${CHROMA_BASIC_AUTH_PASSWORD}"
```

> [!NOTE]
> The above `curl` assumes a localhost forwarding is made to port 8000

### Using custom/existing secret

Create a secret with the auth credentials:

```bash
kubectl create secret generic chromadb-auth-custom --from-literal=token="my-token"
```

To use a custom/existing secret for auth credentials, set `chromadb.auth.existingSecret` to the name of the secret.

```yaml
chromadb:
  auth:
    existingSecret: "chromadb-auth-custom"
```

or

```bash
kubectl create secret generic chromadb-auth-custom --from-literal=token="my-token"
helm install chroma chroma/chromadb --set chromadb.auth.existingSecret="chromadb-auth-custom"
```

Verify the auth is working:

```bash
export CHROMA_TOKEN=$(kubectl --namespace default get secret chromadb-auth-custom -o jsonpath="{.data.token}" | base64 --decode)
export CHROMA_HEADER_NAME=$(kubectl --namespace default get configmap chroma-chromadb-token-auth-config -o jsonpath="{.data.CHROMA_AUTH_TOKEN_TRANSPORT_HEADER}")
curl -v http://localhost:8000/api/v1/collections -H "${CHROMA_HEADER_NAME}: Bearer ${CHROMA_TOKEN}"
```

## Using the chart as a dependency

To use the chart as a dependency, add the following to your `Chart.yaml` file:

```yaml
dependencies:
  - name: chromadb
    version: 0.1.24
    repository: "https://amikos-tech.github.io/chromadb-chart/"
```

Then, run `helm dependency update` to install the chart.

## References

- Chroma: https://docs.trychroma.com/docs/overview/getting-started
- Helm install: https://helm.sh/docs/intro/install/
- Minikube install: https://minikube.sigs.k8s.io/docs/start/