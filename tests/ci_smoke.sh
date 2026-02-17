#!/usr/bin/env bash
set -euo pipefail

CHART_DIR="$(cd "$(dirname "$0")/../charts/chromadb-chart" && pwd)"

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

require_cmd helm
require_cmd yq

echo "==> Running v1 config template tests"
bash "$(dirname "$0")/test_v1_config.sh"

echo "==> Running helm lint"
helm lint "$CHART_DIR"

echo "==> Rendering v1-config with integration extraConfig values"
config="$(helm template test "$CHART_DIR" \
  --set chromadb.apiVersion=1.5.0 \
  --set chromadb.extraConfig.scorecard_enabled=true \
  --set chromadb.extraConfig.circuit_breaker.requests=500 \
  | yq eval 'select(.metadata.name == "v1-config") | .data["config.yaml"]' -)"

if [ -z "${config}" ] || [ "${config}" = "null" ]; then
  echo "Failed to render v1-config config.yaml in ci smoke checks" >&2
  exit 1
fi

printf '%s\n' "$config" | grep -q '^scorecard_enabled: true$'
printf '%s\n' "$config" | grep -q '^circuit_breaker:$'
printf '%s\n' "$config" | grep -q '^  requests: 500$'

echo "ci smoke checks passed"
