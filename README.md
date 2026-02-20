# Kubernetes Chart for Chroma AI application database

[![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/chromadb-helm)](https://artifacthub.io/packages/search?repo=chromadb-helm)

This chart deploys a single-node Chroma database on a Kubernetes cluster using the Helm package manager.

> [!TIP]
> Deploying and managing multiple Chroma nodes support will arrive with
> the [Chroma single-node Operator](https://github.com/amikos-tech/chromadb-operator).


> [!WARNING]
> For Chroma `>= 1.0.0` (Rust server), chart values under `chromadb.auth.*` are legacy and ignored.
> Use network-level security controls (private networking, ingress auth, API gateways, mTLS) when deploying `>= 1.0.0`.

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
  allowReset: true
```

Alternatively you can specify each parameter using the `--set key=value[,key=value]` argument to `helm install`.

```bash
helm install chroma chroma/chromadb --set chromadb.allowReset=true
```

## Chart Configuration Values

| Key                                                 | Type    | Default                               | Description                                                                                                                                                                                                                                                                                                |
|-----------------------------------------------------|---------|---------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `chromadb.apiVersion`                               | string  | `1.5.0` (Chart app version)           | The ChromaDB version. Supported version `0.4.3` - `1.x`                                                                                                                                                                                                                                                    |
| `chromadb.allowReset`                               | boolean | `false`                               | Allows resetting the index (delete all data). Accepts bool or string `true`/`false` (case-insensitive); rendered value is normalized to lowercase.                                                                                                                                                        |
| `chromadb.isPersistent`                             | boolean | `true`                                | `< 1.0.0`: controls PVC plus `IS_PERSISTENT` server mode. `>= 1.0.0`: controls only PVC creation/mounting for `persistDirectory`; the Rust server always writes to disk, so data is ephemeral without a PVC. Accepts bool or string `true`/`false` (case-insensitive); rendered value is normalized to lowercase. |
| `chromadb.persistDirectory`                         | string  | `/data`                               | Absolute path where index data is stored. Used for both Chroma server config and mounted persistent volume path.                                                                                                                                                                                            |
| `chromadb.anonymizedTelemetry`                      | boolean | `false`                               | Legacy PostHog telemetry flag for `< 1.0.0`. **Note**: This has no effect in Chroma `>= 1.0.0`; use `chromadb.telemetry.*` for OTEL.                                                                                                                                                                      |
| `chromadb.corsAllowOrigins`                         | list    | `[]`                                  | List of allowed CORS origins. Wildcard `["*"]` is supported.                                                                                                                                                                                                                                               |
| `chromadb.apiImpl`                                  | string  | `- "chromadb.api.segment.SegmentAPI"` | Legacy/removed key kept for historical compatibility in docs. The chart does not read this value in current versions.                                                                                                                                                                                     |
| `chromadb.serverHost`                               | string  | `0.0.0.0`                             | The API server host.                                                                                                                                                                                                                                                                                       |
| `chromadb.serverHttpPort`                           | int     | `8000`                                | The API server port. For `>= 1.0.0`, this sets `port` in `v1-config`; `CHROMA_SERVER_HTTP_PORT` is a legacy env var used only for `< 1.0.0`.                                                                                                                                                            |
| `chromadb.data.volumeSize`                          | string  | `1Gi`                                 | The data volume size.                                                                                                                                                                                                                                                                                      |
| `chromadb.data.storageClass`                        | string  | `null` (default storage class)        | The storage class                                                                                                                                                                                                                                                                                          |
| `chromadb.data.accessModes`                         | string  | `ReadWriteOnce`                       | The volume access mode.                                                                                                                                                                                                                                                                                    |
| `chromadb.data.retentionPolicyOnDelete`             | string  | `"Delete"`                            | The retention policy on removal. By default the PVC will be remove when Chroma chart is uninstalled. If you wish to keep it set this value to `Retain`.                                                                                                                                                    |
| `chromadb.auth.enabled`                             | boolean | `true`                                | Legacy auth toggle for `< 1.0.0`. Ignored for `>= 1.0.0`.                                                                                                                                                                                                                                                 |
| `chromadb.auth.type`                                | string  | `token`                               | Legacy auth type for `< 1.0.0`. Supported values are `token` (apiVersion>=0.4.8) and `basic` (apiVersion>=0.4.7). Ignored for `>= 1.0.0`.                                                                                                                                                                 |
| `chromadb.auth.token.headerType`                    | string  | `Authorization`                       | Legacy token header type for `< 1.0.0`. Possible values: `Authorization` or `X-Chroma-Token` (also works with `X_CHROMA_TOKEN`). Ignored for `>= 1.0.0`.                                                                                                                                                  |
| `chromadb.auth.existingSecret`                      | string  | `""`                                  | Legacy auth secret reference for `< 1.0.0`. For token auth the secret should contain `token`; for basic auth it should contain `username` and `password`. Ignored for `>= 1.0.0`.                                                                                                                         |
| `global.imageRegistry`                              | string  | `""`                                  | Global image registry override applied to all images (useful for air-gapped environments).                                                                                                                                                                                                                 |
| `image.registry`                                    | string  | `""`                                  | Registry override for the ChromaDB image. Takes precedence over `global.imageRegistry`.                                                                                                                                                                                                                    |
| `image.repository`                                  | string  | `ghcr.io/chroma-core/chroma`          | The repository of the ChromaDB image.                                                                                                                                                                                                                                                                      |
| `image.tag`                                         | string  | `""`                                  | Tag override for the ChromaDB image. Defaults to `Chart.AppVersion`.                                                                                                                                                                                                                                       |
| `image.digest`                                      | string  | `""`                                  | Digest override for the ChromaDB image. When set, takes precedence over `image.tag`.                                                                                                                                                                                                                       |
| `image.pullPolicy`                                  | string  | `IfNotPresent`                        | Image pull policy for the ChromaDB image.                                                                                                                                                                                                                                                                  |
| `initImage.registry`                                | string  | `""`                                  | Registry override for the init container image. Takes precedence over `global.imageRegistry`.                                                                                                                                                                                                              |
| `initImage.repository`                              | string  | `docker.io/httpd`                     | The repository of the init container image.                                                                                                                                                                                                                                                                |
| `initImage.tag`                                     | string  | `"2"`                                 | Tag for the init container image.                                                                                                                                                                                                                                                                          |
| `initImage.digest`                                  | string  | `""`                                  | Digest override for the init container image. When set, takes precedence over `initImage.tag`.                                                                                                                                                                                                             |
| `initImage.pullPolicy`                              | string  | `IfNotPresent`                        | Image pull policy for the init container image.                                                                                                                                                                                                                                                            |
| `chromadb.logging.root`                             | string  | `INFO`                                | Legacy Python logging level for `< 1.0.0`. Ignored for `>= 1.0.0`.                                                                                                                                                                                                                                         |
| `chromadb.logging.chromadb`                         | string  | `DEBUG`                               | Legacy Python logging level for `< 1.0.0`. Ignored for `>= 1.0.0`.                                                                                                                                                                                                                                         |
| `chromadb.logging.uvicorn`                          | string  | `INFO`                                | Legacy Python logging level for `< 1.0.0`. Ignored for `>= 1.0.0`.                                                                                                                                                                                                                                         |
| `chromadb.logConfigFileLocation`                    | string  | `/chroma/log_config.yaml`             | Path to the Python log config file for `< 1.0.0`. Ignored for `>= 1.0.0`.                                                                                                                                                                                                                                  |
| `chromadb.logConfigMap`                             | string  | `null`                                | ConfigMap name for Python log configuration on `< 1.0.0`. Ignored for `>= 1.0.0`.                                                                                                                                                                                                                          |
| `chromadb.maintenance.collection_cache_policy`      | string  | `null`                                | Legacy maintenance setting for `< 1.0.0`. Possible values: null or `LRU`. Ignored for `>= 1.0.0`.                                                                                                                                                                                                         |
| `chromadb.maintenance.collection_cache_limit_bytes` | int     | `1000000000`                          | Legacy maintenance setting for `< 1.0.0`. Ignored for `>= 1.0.0`.                                                                                                                                                                                                                                          |
| `chromadb.maxPayloadSizeBytes`                      | int     | `41943040`                            | The size in bytes of  the maximum payload that can be sent to Chroma. This is supported in v1.0.0 or later.                                                                                                                                                                                                |
| `chromadb.telemetry.enabled`                        | boolean | `false`                               | Enables chroma to send OTEL telemetry                                                                                                                                                                                                                                                                      |
| `chromadb.telemetry.endpoint`                       | string  | ``                                    | OTEL collector endpoint e.g. "http://otel-collector:4317"                                                                                                                                                                                                                                                  |
| `chromadb.telemetry.serviceName`                    | string  | `chroma`                              | The service name that will show up in traces.                                                                                                                                                                                                                                                              |
| `chromadb.telemetry.filters`                        | list    | `[]`                                  | Optional `open_telemetry.filters` entries for per-crate trace filtering in Chroma >= 1.0.0.                                                                                                                                                                                                                |
| `chromadb.sqliteFilename`                           | string  | `""`                                  | Optional `sqlite_filename` for Chroma >= 1.0.0. Empty means server default (`chroma.sqlite3`).                                                                                                                                                                                                             |
| `chromadb.sqliteDb.hashType`                        | string  | `""`                                  | Optional `sqlitedb.hash_type` (`md5` or `sha256`) for Chroma >= 1.0.0. Empty means server default (`md5`).                                                                                                                                                                                                 |
| `chromadb.sqliteDb.migrationMode`                   | string  | `""`                                  | Optional `sqlitedb.migration_mode` (`apply` or `validate`) for Chroma >= 1.0.0. Empty means server default (`apply`).                                                                                                                                                                                      |
| `chromadb.circuitBreaker.requests`                  | int     | `null`                                | Optional `circuit_breaker.requests` for Chroma >= 1.0.0. Set `0` to disable; `null` leaves server default (`0`).                                                                                                                                                                                            |
| `chromadb.segmentManager.hnswIndexPoolCacheConfig`  | object  | `{}`                                  | Optional `segment_manager.hnsw_index_pool_cache_config` object for Chroma >= 1.0.0.                                                                                                                                                                                                                         |
| `imagePullSecrets`                                  | list    | `[]`                                  | List of image pull secrets for the ChromaDB pod (e.g. `[{name: "my-secret"}]`).                                                                                                                                                                                                                            |
| `global.imagePullSecrets`                           | list    | `[]`                                  | Global image pull secrets shared across all subcharts. Merged with `imagePullSecrets`.                                                                                                                                                                                                                     |
| `serviceAccount.create`                             | boolean | `true`                                | Specifies whether the chart should create a ServiceAccount.                                                                                                                                                                                                                                                 |
| `serviceAccount.annotations`                        | object  | `{}`                                  | Annotations added to the created ServiceAccount.                                                                                                                                                                                                                                                            |
| `serviceAccount.name`                               | string  | `""`                                  | ServiceAccount name used by the pod. If empty and `serviceAccount.create=true`, the chart fullname is used; if `serviceAccount.create=false`, Kubernetes `default` is used unless overridden.                                                                                                              |
| `serviceAccount.automountServiceAccountToken`       | boolean | `true`                                | Sets `automountServiceAccountToken` on the created ServiceAccount.                                                                                                                                                                                                                                          |
| `chromadb.extraConfig`                              | object  | `{}`                                  | Extra config keys merged into the v1 server config (>= 1.0.0). Overrides chart-managed keys. See [Extra Config](#extra-config).                                                                                                                                                                           |
| `commonLabels`                                      | object  | `{}`                                  | Additional labels applied to all chart resources (StatefulSet, Service, Ingress, ConfigMaps, Secrets, PVCs, test Jobs).                                                                                                                                                                                    |
| `podLabels`                                         | object  | `{}`                                  | Additional labels applied to pods only. Does not affect `matchLabels`.                                                                                                                                                                                                                                     |

### Legacy values for `< 1.0.0`

For Chroma `>= 1.0.0` (Rust server), the chart keeps the following values only for backward compatibility and ignores them:

- `chromadb.anonymizedTelemetry`
- `chromadb.logging.*`
- `chromadb.logConfigFileLocation`
- `chromadb.logConfigMap`
- `chromadb.maintenance.*`
- `chromadb.auth.*`
- `chromadb.apiImpl` (removed; no longer read by the chart)

Use `chromadb.telemetry.*` and `chromadb.extraConfig` to configure Rust server behavior in `>= 1.0.0`.

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
> Token auth is enabled by default for `< 1.0.0`. For `>= 1.0.0`, `chromadb.auth.*` values are ignored.

By default, the chart will use a `chromadb-auth` secret in Chroma's namespace to authenticate requests. This secret is
generated at install time.

Chroma authentication is supported for the following API versions:

- `basic` >= 0.4.7 and < 1.0.0
- `token` >= 0.4.8 and < 1.0.0

> [!NOTE]
> Using auth parameters outside the supported versions above will result in auth settings being ignored.

### Token Auth

Token Auth works with two types of headers that can be configured via `chromadb.auth.token.headerType`:

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
    version: 0.2.0
    repository: "https://amikos-tech.github.io/chromadb-chart/"
```

Then, run `helm dependency update` to install the chart.

When using as a subchart, `global.imagePullSecrets` lets you define pull secrets once in the parent chart and have them propagated to all subcharts (including ChromaDB). Chart-level `imagePullSecrets` only applies to this chart. Both lists are merged, so there is no conflict if the same secret appears in both — though it may appear as a duplicate, Kubernetes handles this gracefully.

## Rust v1 Config Options

For Chroma >= 1.0.0 (Rust server), these dedicated values map directly to the server config:

- `chromadb.sqliteFilename` -> `sqlite_filename`
- `chromadb.sqliteDb.hashType` -> `sqlitedb.hash_type`
- `chromadb.sqliteDb.migrationMode` -> `sqlitedb.migration_mode`
- `chromadb.circuitBreaker.requests` -> `circuit_breaker.requests`
- `chromadb.telemetry.filters` -> `open_telemetry.filters`
- `chromadb.segmentManager.hnswIndexPoolCacheConfig` -> `segment_manager.hnsw_index_pool_cache_config`

Example:

```yaml
chromadb:
  sqliteFilename: "custom.db"
  sqliteDb:
    hashType: "sha256"
    migrationMode: "validate"
  circuitBreaker:
    requests: 500
  telemetry:
    filters:
      - crate_name: "chroma_frontend"
        filter_level: "info"
  segmentManager:
    hnswIndexPoolCacheConfig:
      policy: "memory"
      capacity: 65536
```

## Extra Config

For Chroma >= 1.0.0 (Rust server), `chromadb.extraConfig` lets you inject arbitrary config keys into the server's YAML
config file. This is useful for setting options not yet exposed as dedicated chart values.

```yaml
chromadb:
  extraConfig:
    compactor:
      disabled_collections: []
```

> [!WARNING]
> Keys in `extraConfig` override chart-managed and dedicated keys of the same name.
> Dedicated value validation (for example enum/range checks on `sqlitedb` and `circuit_breaker`)
> is applied before `extraConfig` merge, so overrides in `extraConfig` are treated as advanced
> escape hatches and are not re-validated by the chart.
>
> Overriding `port` or `listen_address` via `extraConfig` is **not allowed** and will cause
> template rendering to fail. Use `chromadb.serverHttpPort` and `chromadb.serverHost` instead
> so that the Service, container port, and health probes remain in sync.

## References

- Chroma: https://docs.trychroma.com/docs/overview/getting-started
- Helm install: https://helm.sh/docs/intro/install/
- Minikube install: https://minikube.sigs.k8s.io/docs/start/
