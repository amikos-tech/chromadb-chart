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
  local config
  output=$(helm template test "$CHART_DIR" "$@" 2>&1) || {
    echo "TEMPLATE_ERROR: $output" >&2
    return 1
  }
  config=$(echo "$output" | yq eval 'select(.metadata.name == "v1-config") | .data["config.yaml"]' -)
  if [ -z "${config}" ] || [ "${config}" = "null" ]; then
    echo "TEMPLATE_ERROR: v1-config ConfigMap not found in rendered output" >&2
    return 1
  fi
  echo "$config"
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

get_statefulset_value() {
  local expr="$1"; shift
  local output
  output=$(helm template test "$CHART_DIR" "$@" --show-only templates/statefulset.yaml 2>&1) || {
    echo "TEMPLATE_ERROR: $output" >&2
    return 1
  }
  echo "$output" | yq eval "$expr" -
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
assert_config_key_missing "sqlite_filename absent by default" "$config" "sqlite_filename"
assert_config_key_missing "sqlitedb absent by default" "$config" "sqlitedb"
assert_config_key_missing "circuit_breaker absent by default" "$config" "circuit_breaker"
assert_config_key_missing "segment_manager absent by default" "$config" "segment_manager"

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
echo "16. Dedicated sqlite/sqlitedb/circuit breaker options"
config=$(get_v1_config \
  --set 'chromadb.sqliteFilename=custom.sqlite3' \
  --set 'chromadb.sqliteDb.hashType=sha256' \
  --set 'chromadb.sqliteDb.migrationMode=validate' \
  --set 'chromadb.circuitBreaker.requests=500')
assert_config_key "sqlite_filename from dedicated value" "$config" "sqlite_filename" "custom.sqlite3"
assert_config_key "sqlitedb.hash_type from dedicated value" "$config" "sqlitedb.hash_type" "sha256"
assert_config_key "sqlitedb.migration_mode from dedicated value" "$config" "sqlitedb.migration_mode" "validate"
assert_config_key "circuit_breaker.requests from dedicated value" "$config" "circuit_breaker.requests" "500"

echo ""
echo "17. Dedicated telemetry filters"
config=$(get_v1_config \
  --set 'chromadb.telemetry.filters[0].crate_name=chroma_frontend' \
  --set 'chromadb.telemetry.filters[0].filter_level=info')
assert_config_key "otel filters crate_name from dedicated value" "$config" "open_telemetry.filters[0].crate_name" "chroma_frontend"
assert_config_key "otel filters filter_level from dedicated value" "$config" "open_telemetry.filters[0].filter_level" "info"
assert_config_key_missing "otel endpoint absent when telemetry disabled" "$config" "open_telemetry.endpoint"

echo ""
echo "18. Dedicated segment manager cache config"
config=$(get_v1_config \
  --set 'chromadb.segmentManager.hnswIndexPoolCacheConfig.policy=memory' \
  --set 'chromadb.segmentManager.hnswIndexPoolCacheConfig.capacity=65536')
assert_config_key "segment_manager cache policy from dedicated value" "$config" "segment_manager.hnsw_index_pool_cache_config.policy" "memory"
assert_config_key "segment_manager cache capacity from dedicated value" "$config" "segment_manager.hnsw_index_pool_cache_config.capacity" "65536"

echo ""
echo "19. Invalid sqliteDb.hashType fails"
assert_template_fails "sqliteDb.hashType rejects invalid enum value" \
  --set 'chromadb.sqliteDb.hashType=sha1'

echo ""
echo "20. Invalid sqliteDb.migrationMode fails"
assert_template_fails "sqliteDb.migrationMode rejects invalid enum value" \
  --set 'chromadb.sqliteDb.migrationMode=skip'

echo ""
echo "21. Negative circuitBreaker.requests fails"
assert_template_fails "circuitBreaker.requests rejects negative value" \
  --set 'chromadb.circuitBreaker.requests=-1'

echo ""
echo "22. circuitBreaker.requests accepts 0 (disable)"
config=$(get_v1_config --set 'chromadb.circuitBreaker.requests=0')
assert_config_key "circuit_breaker.requests allows zero" "$config" "circuit_breaker.requests" "0"

echo ""
echo "23. sqliteDb enums are case-normalized"
config=$(get_v1_config \
  --set 'chromadb.sqliteDb.hashType=SHA256' \
  --set 'chromadb.sqliteDb.migrationMode=Validate')
assert_config_key "sqlitedb.hash_type lowercased" "$config" "sqlitedb.hash_type" "sha256"
assert_config_key "sqlitedb.migration_mode lowercased" "$config" "sqlitedb.migration_mode" "validate"

echo ""
echo "24. telemetry.enabled with filters renders all OTEL fields"
config=$(get_v1_config \
  --set 'chromadb.telemetry.enabled=true' \
  --set 'chromadb.telemetry.endpoint=http://otel:4317' \
  --set 'chromadb.telemetry.serviceName=my-chroma' \
  --set 'chromadb.telemetry.filters[0].crate_name=chroma_frontend' \
  --set 'chromadb.telemetry.filters[0].filter_level=debug')
assert_config_key "otel endpoint with filters" "$config" "open_telemetry.endpoint" "http://otel:4317"
assert_config_key "otel service_name with filters" "$config" "open_telemetry.service_name" "my-chroma"
assert_config_key "otel filters with telemetry enabled" "$config" "open_telemetry.filters[0].filter_level" "debug"

echo ""
echo "25. extraConfig overrides dedicated values for the same key"
config=$(get_v1_config \
  --set 'chromadb.sqliteDb.hashType=sha256' \
  --set 'chromadb.extraConfig.sqlitedb.hash_type=md5')
assert_config_key "extraConfig wins over dedicated sqlitedb.hash_type" "$config" "sqlitedb.hash_type" "md5"

echo ""
echo "26. Rust v1-only dedicated values are ignored on < 1.0.0"
config=$(get_v1_config \
  --set 'chromadb.apiVersion=0.6.3' \
  --set 'chromadb.sqliteFilename=custom.sqlite3' \
  --set 'chromadb.sqliteDb.hashType=sha256' \
  --set 'chromadb.sqliteDb.migrationMode=validate' \
  --set 'chromadb.circuitBreaker.requests=500' \
  --set 'chromadb.telemetry.filters[0].crate_name=chroma_frontend' \
  --set 'chromadb.segmentManager.hnswIndexPoolCacheConfig.capacity=65536')
assert_config_key_missing "sqlite_filename omitted on < 1.0.0" "$config" "sqlite_filename"
assert_config_key_missing "sqlitedb omitted on < 1.0.0" "$config" "sqlitedb"
assert_config_key_missing "circuit_breaker omitted on < 1.0.0" "$config" "circuit_breaker"
assert_config_key_missing "segment_manager omitted on < 1.0.0" "$config" "segment_manager"
assert_config_key_missing "otel filters omitted on < 1.0.0" "$config" "open_telemetry.filters"

echo ""
echo "27. extraConfig must be a map/object"
assert_template_fails "extraConfig rejects list values" \
  --set 'chromadb.extraConfig[0]=invalid'

echo ""
echo "28. extraConfig must reject scalar values"
assert_template_fails "extraConfig rejects scalar string values" \
  --set 'chromadb.extraConfig=invalid'

echo ""
echo "29. allowReset accepts case-insensitive string booleans"
config=$(get_v1_config --set-string 'chromadb.allowReset=TRUE')
assert_config_key "allow_reset normalizes uppercase TRUE to true" "$config" "allow_reset" "true"

echo ""
echo "30. isPersistent accepts case-insensitive string booleans"
is_persistent_env=$(get_statefulset_env_value "IS_PERSISTENT" --set 'chromadb.apiVersion=0.6.3' --set-string 'chromadb.isPersistent=FALSE')
assert_equal "IS_PERSISTENT normalizes uppercase FALSE to false" "$is_persistent_env" "false"
pvc_templates=$(get_statefulset_value '.spec.volumeClaimTemplates | length // 0' --set-string 'chromadb.isPersistent=FALSE')
assert_equal "volumeClaimTemplates omitted when isPersistent is false string" "$pvc_templates" "0"

echo ""
echo "31. allowReset rejects invalid string values"
assert_template_fails "allowReset rejects non-boolean strings" \
  --set-string 'chromadb.allowReset=yes'

echo ""
echo "32. isPersistent rejects invalid string values"
assert_template_fails "isPersistent rejects non-boolean strings" \
  --set-string 'chromadb.isPersistent=on'

echo ""
echo "33. persistDirectory must be an absolute path"
assert_template_fails "persistDirectory rejects relative paths" \
  --set-string 'chromadb.persistDirectory=data'
assert_template_fails "persistDirectory rejects empty strings" \
  --set-string 'chromadb.persistDirectory='

echo ""
echo "--- Results: $PASS passed, $FAIL failed ---"
[ "$FAIL" -eq 0 ] || exit 1
