#!/usr/bin/env bash
set -euo pipefail

CHART_DIR="$(cd "$(dirname "$0")/../charts/chromadb-chart" && pwd)"
PASS=0
FAIL=0

assert_config_key() {
  local desc="$1" yaml="$2" key="$3" expected="$4"
  actual=$(echo "$yaml" | yq eval ".$key" -)
  if [ "$actual" = "$expected" ]; then
    echo "  PASS: $desc"
    PASS=$((PASS+1))
  else
    echo "  FAIL: $desc (expected '$expected', got '$actual')"
    FAIL=$((FAIL+1))
  fi
}

assert_config_key_missing() {
  local desc="$1" yaml="$2" key="$3"
  actual=$(echo "$yaml" | yq eval ".$key" -)
  if [ "$actual" = "null" ]; then
    echo "  PASS: $desc"
    PASS=$((PASS+1))
  else
    echo "  FAIL: $desc (expected key '$key' to be absent, got '$actual')"
    FAIL=$((FAIL+1))
  fi
}

assert_fail() {
  local desc="$1" output="$2"
  if echo "$output" | grep -q "Error:"; then
    echo "  PASS: $desc"
    PASS=$((PASS+1))
  else
    echo "  FAIL: $desc (expected helm template to fail)"
    FAIL=$((FAIL+1))
  fi
}

get_v1_config() {
  helm template test "$CHART_DIR" "$@" 2>/dev/null \
    | yq eval 'select(.metadata.name == "v1-config") | .data["config.yaml"]' -
}

# --- Test suite ---

echo "=== v1-config template tests (Chroma 1.5.0) ==="

echo ""
echo "1. Default values"
config=$(get_v1_config)
assert_config_key "port defaults to 8000" "$config" "port" "8000"
assert_config_key "listen_address defaults to 0.0.0.0" "$config" "listen_address" "0.0.0.0"
assert_config_key "max_payload_size_bytes defaults to 41943040" "$config" "max_payload_size_bytes" "41943040"
assert_config_key "persist_path defaults to /data" "$config" "persist_path" "/data"
assert_config_key "allow_reset defaults to false" "$config" "allow_reset" "false"
assert_config_key_missing "cors_allow_origins absent when empty" "$config" "cors_allow_origins"
assert_config_key_missing "open_telemetry absent when disabled" "$config" "open_telemetry"

echo ""
echo "2. CORS wildcard on >= 1.0.0 (should work)"
config=$(get_v1_config --set 'chromadb.corsAllowOrigins={*}')
assert_config_key "cors_allow_origins contains wildcard" "$config" "cors_allow_origins[0]" "*"

echo ""
echo "3. CORS multiple origins"
config=$(get_v1_config --set 'chromadb.corsAllowOrigins={https://a.com,https://b.com}')
assert_config_key "first origin" "$config" "cors_allow_origins[0]" "https://a.com"
assert_config_key "second origin" "$config" "cors_allow_origins[1]" "https://b.com"

echo ""
echo "4. OpenTelemetry enabled"
config=$(get_v1_config \
  --set 'chromadb.telemetry.enabled=true' \
  --set 'chromadb.telemetry.endpoint=http://otel:4317' \
  --set 'chromadb.telemetry.serviceName=my-chroma')
assert_config_key "otel endpoint" "$config" "open_telemetry.endpoint" "http://otel:4317"
assert_config_key "otel service_name" "$config" "open_telemetry.service_name" "my-chroma"

echo ""
echo "5. Custom server settings"
config=$(get_v1_config \
  --set 'chromadb.serverHttpPort=9000' \
  --set 'chromadb.serverHost=127.0.0.1' \
  --set 'chromadb.allowReset=true' \
  --set 'chromadb.persistDirectory=/mnt/data' \
  --set 'chromadb.maxPayloadSizeBytes=52428800')
assert_config_key "custom port" "$config" "port" "9000"
assert_config_key "custom listen_address" "$config" "listen_address" "127.0.0.1"
assert_config_key "allow_reset true" "$config" "allow_reset" "true"
assert_config_key "custom persist_path" "$config" "persist_path" "/mnt/data"
assert_config_key "custom max_payload_size_bytes" "$config" "max_payload_size_bytes" "52428800"

echo ""
echo "6. extraConfig merge"
config=$(get_v1_config \
  --set 'chromadb.extraConfig.circuit_breaker.requests=500' \
  --set 'chromadb.extraConfig.sqlite_filename=custom.db')
assert_config_key "circuit_breaker.requests from extraConfig" "$config" "circuit_breaker.requests" "500"
assert_config_key "sqlite_filename from extraConfig" "$config" "sqlite_filename" "custom.db"
assert_config_key "port still present after merge" "$config" "port" "8000"

echo ""
echo "7. extraConfig overrides chart-managed keys"
config=$(get_v1_config --set 'chromadb.extraConfig.port=9999')
assert_config_key "extraConfig overrides port" "$config" "port" "9999"

echo ""
echo "--- Results: $PASS passed, $FAIL failed ---"
[ "$FAIL" -eq 0 ] || exit 1
