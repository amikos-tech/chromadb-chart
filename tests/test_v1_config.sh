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

get_v1_config() {
  local output
  output=$(helm template test "$CHART_DIR" "$@" 2>&1) || {
    echo "TEMPLATE_ERROR: $output" >&2
    return 1
  }
  echo "$output" | yq eval 'select(.metadata.name == "v1-config") | .data["config.yaml"]' -
}

get_statefulset_env_value() {
  local env_name="$1"; shift
  local output
  output=$(helm template test "$CHART_DIR" "$@" --show-only templates/statefulset.yaml 2>&1) || {
    echo "TEMPLATE_ERROR: $output" >&2
    return 1
  }
  echo "$output" | yq eval ".spec.template.spec.containers[] | select(.name == \"chromadb\") | [.env[]? | select(.name == \"$env_name\") | .value][0] // \"null\"" -
}

assert_equal() {
  local desc="$1" actual="$2" expected="$3"
  if [ "$actual" = "$expected" ]; then
    echo "  PASS: $desc"
    PASS=$((PASS+1))
  else
    echo "  FAIL: $desc (expected '$expected', got '$actual')"
    FAIL=$((FAIL+1))
  fi
}

assert_template_fails() {
  local desc="$1"; shift
  local output
  if output=$(helm template test "$CHART_DIR" "$@" 2>&1); then
    echo "  FAIL: $desc (expected template to fail, but it succeeded)"
    FAIL=$((FAIL+1))
  else
    echo "  PASS: $desc"
    PASS=$((PASS+1))
  fi
}

# --- Test suite ---

echo "=== v1-config template tests ==="

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
echo "2. CORS wildcard (should work)"
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
echo "7. extraConfig override of port fails"
assert_template_fails "extraConfig.port override rejected" \
  --set 'chromadb.extraConfig.port=9999'

echo ""
echo "8. extraConfig override of listen_address fails"
assert_template_fails "extraConfig.listen_address override rejected" \
  --set 'chromadb.extraConfig.listen_address=127.0.0.1'

echo ""
echo "9. telemetry enabled without endpoint fails"
assert_template_fails "telemetry.enabled without endpoint rejected" \
  --set 'chromadb.telemetry.enabled=true'

echo ""
# v1-config is only mounted for >= 1.0.0; this test validates template
# rendering only, not runtime CORS behavior for pre-1.0 versions.
echo "10. CORS wildcard on < 1.0.0 (ConfigMap renders)"
config=$(get_v1_config --set 'chromadb.corsAllowOrigins={*}' --set 'chromadb.apiVersion=0.6.3')
assert_config_key "cors_allow_origins wildcard for pre-1.0" "$config" "cors_allow_origins[0]" "*"

echo ""
echo "11. CHROMA_SERVER_HTTP_PORT omitted for >= 1.0.0"
server_http_port_env=$(get_statefulset_env_value "CHROMA_SERVER_HTTP_PORT")
assert_equal "CHROMA_SERVER_HTTP_PORT missing on >= 1.0.0" "$server_http_port_env" "null"

echo ""
echo "12. CHROMA_SERVER_HTTP_PORT set for < 1.0.0"
server_http_port_env=$(get_statefulset_env_value "CHROMA_SERVER_HTTP_PORT" --set 'chromadb.apiVersion=0.6.3' --set 'chromadb.serverHttpPort=9000')
assert_equal "CHROMA_SERVER_HTTP_PORT is 9000 on < 1.0.0" "$server_http_port_env" "9000"

echo ""
echo "13. CHROMA_SERVER_HTTP_PORT omitted at boundary 1.0.0"
server_http_port_env=$(get_statefulset_env_value "CHROMA_SERVER_HTTP_PORT" --set 'chromadb.apiVersion=1.0.0')
assert_equal "CHROMA_SERVER_HTTP_PORT missing on 1.0.0" "$server_http_port_env" "null"

echo ""
echo "14. CHROMA_SERVER_HTTP_PORT defaults to 8000 on < 1.0.0"
server_http_port_env=$(get_statefulset_env_value "CHROMA_SERVER_HTTP_PORT" --set 'chromadb.apiVersion=0.6.3')
assert_equal "CHROMA_SERVER_HTTP_PORT is default 8000 on < 1.0.0" "$server_http_port_env" "8000"

echo ""
echo "15. Custom serverHttpPort on >= 1.0.0 does not create legacy env var"
server_http_port_env=$(get_statefulset_env_value "CHROMA_SERVER_HTTP_PORT" --set 'chromadb.apiVersion=1.5.0' --set 'chromadb.serverHttpPort=9000')
assert_equal "CHROMA_SERVER_HTTP_PORT remains absent on >= 1.0.0 with custom port" "$server_http_port_env" "null"

echo ""
echo "--- Results: $PASS passed, $FAIL failed ---"
[ "$FAIL" -eq 0 ] || exit 1
