{{/*
Expand the name of the chart.
*/}}
{{- define "chart.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "chart.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "chart.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Returns the proper image name.
*/}}
{{- define "chart.images.chroma" -}}
{{- $registryName := default .Values.image.registry ((.Values.global).imageRegistry) -}}
{{- $repositoryName := .Values.image.repository -}}
{{- $separator := ":" -}}
{{- $termination := .Values.image.tag | toString -}}
{{- if not .Values.image.tag -}}
  {{ if .Values.chromadb.apiVersion -}}
    {{- $termination = .Values.chromadb.apiVersion | toString -}}
  {{- else -}}
    {{- $termination = .Chart.AppVersion | toString -}}
  {{- end -}}
{{- end -}}
{{- if .Values.image.digest -}}
    {{- $separator = "@" -}}
    {{- $termination = .Values.image.digest | toString -}}
{{- end -}}
{{- if $registryName -}}
    {{- printf "%s/%s%s%s" $registryName $repositoryName $separator $termination -}}
{{- else -}}
    {{- printf "%s%s%s"  $repositoryName $separator $termination -}}
{{- end -}}
{{- end }}

{{/*
Returns the proper initImage name.
*/}}
{{- define "chart.images.initImage" -}}
{{- $registryName := default .Values.initImage.registry ((.Values.global).imageRegistry) -}}
{{- $repositoryName := .Values.initImage.repository -}}
{{- $separator := ":" -}}
{{- $termination := .Values.initImage.tag | toString -}}
{{- if .Values.initImage.digest -}}
    {{- $separator = "@" -}}
    {{- $termination = .Values.initImage.digest | toString -}}
{{- end -}}
{{- if $registryName -}}
    {{- printf "%s/%s%s%s" $registryName $repositoryName $separator $termination -}}
{{- else -}}
    {{- printf "%s%s%s"  $repositoryName $separator $termination -}}
{{- end -}}
{{- end }}

{{/*
Common labels
*/}}
{{- define "chart.labels" -}}
helm.sh/chart: {{ include "chart.chart" . }}
{{ include "chart.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- with .Values.commonLabels }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "chart.selectorLabels" -}}
app.kubernetes.io/name: {{ include "chart.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "chart.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "chart.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Get the chroma api version
*/}}
{{- define "chromadb.apiVersion" -}}
{{- if .Values.chromadb.apiVersion }}
{{- .Values.chromadb.apiVersion }}
{{- else }}
{{- .Chart.AppVersion }}
{{- end }}
{{- end }}

{{/*
Normalize boolean values passed as bool or string.
Returns "true" or "false".
*/}}
{{- define "chromadb.boolValue" -}}
{{- $name := .name -}}
{{- $value := .value -}}
{{- if kindIs "bool" $value -}}
  {{- if $value }}true{{ else }}false{{ end -}}
{{- else if kindIs "string" $value -}}
  {{- $normalized := lower (trim $value) -}}
  {{- if or (eq $normalized "true") (eq $normalized "false") -}}
    {{- $normalized -}}
  {{- else -}}
    {{- fail (printf "%s must be true or false (case-insensitive), got %q" $name $value) -}}
  {{- end -}}
{{- else -}}
  {{- fail (printf "%s must be a boolean or a string true/false, got type %s" $name (kindOf $value)) -}}
{{- end -}}
{{- end }}

{{/*
Normalize/validate chromadb.allowReset.
*/}}
{{- define "chromadb.allowReset" -}}
{{- include "chromadb.boolValue" (dict "name" "chromadb.allowReset" "value" .Values.chromadb.allowReset) -}}
{{- end }}

{{/*
Normalize/validate chromadb.isPersistent.
*/}}
{{- define "chromadb.isPersistent" -}}
{{- include "chromadb.boolValue" (dict "name" "chromadb.isPersistent" "value" .Values.chromadb.isPersistent) -}}
{{- end }}

{{/*
Validate and normalize the persist directory path.
*/}}
{{- define "chromadb.persistDirectory" -}}
{{- $raw := .Values.chromadb.persistDirectory -}}
{{- if not (kindIs "string" $raw) -}}
  {{- fail (printf "chromadb.persistDirectory must be a string absolute path, got type %s" (kindOf $raw)) -}}
{{- end -}}
{{- $path := trim $raw -}}
{{- if eq $path "" -}}
  {{- fail "chromadb.persistDirectory must not be empty" -}}
{{- end -}}
{{- if not (hasPrefix "/" $path) -}}
  {{- fail (printf "chromadb.persistDirectory must be an absolute path starting with '/': got %q" $raw) -}}
{{- end -}}
{{- $path -}}
{{- end }}

{{/*
Build the server config dict for the v1-config ConfigMap.
*/}}
{{- define "chromadb.serverConfig" -}}
{{- $port := .Values.chromadb.serverHttpPort | int -}}
{{- if le $port 0 -}}
  {{- fail (printf "chromadb.serverHttpPort must be a positive integer, got: %v" .Values.chromadb.serverHttpPort) -}}
{{- end -}}
{{- $maxPayload := .Values.chromadb.maxPayloadSizeBytes | int64 -}}
{{- if le $maxPayload 0 -}}
  {{- fail (printf "chromadb.maxPayloadSizeBytes must be a positive integer, got: %v" .Values.chromadb.maxPayloadSizeBytes) -}}
{{- end -}}
{{- $isV1 := semverCompare ">= 1.0.0" (include "chromadb.apiVersion" .) -}}
{{- $allowReset := eq (include "chromadb.allowReset" .) "true" -}}
{{- $persistDirectory := include "chromadb.persistDirectory" . -}}
{{- $config := dict -}}
{{- $_ := set $config "port" $port -}}
{{- $_ := set $config "listen_address" .Values.chromadb.serverHost -}}
{{- $_ := set $config "max_payload_size_bytes" $maxPayload -}}
{{- $_ := set $config "persist_path" $persistDirectory -}}
{{- $_ := set $config "allow_reset" $allowReset -}}
{{- if .Values.chromadb.corsAllowOrigins -}}
  {{- $_ := set $config "cors_allow_origins" .Values.chromadb.corsAllowOrigins -}}
{{- end -}}
{{- if $isV1 -}}
  {{- with .Values.chromadb.sqliteFilename -}}
    {{- $_ := set $config "sqlite_filename" . -}}
  {{- end -}}
  {{- $sqlitedb := dict -}}
  {{- $sqliteHashType := .Values.chromadb.sqliteDb.hashType | default "" -}}
  {{- if $sqliteHashType -}}
    {{- $sqliteHashType = lower $sqliteHashType -}}
    {{- if not (or (eq $sqliteHashType "md5") (eq $sqliteHashType "sha256")) -}}
      {{- fail (printf "chromadb.sqliteDb.hashType must be one of: md5, sha256 (got %q)" .Values.chromadb.sqliteDb.hashType) -}}
    {{- end -}}
    {{- $_ := set $sqlitedb "hash_type" $sqliteHashType -}}
  {{- end -}}
  {{- $sqliteMigrationMode := .Values.chromadb.sqliteDb.migrationMode | default "" -}}
  {{- if $sqliteMigrationMode -}}
    {{- $sqliteMigrationMode = lower $sqliteMigrationMode -}}
    {{- if not (or (eq $sqliteMigrationMode "apply") (eq $sqliteMigrationMode "validate")) -}}
      {{- fail (printf "chromadb.sqliteDb.migrationMode must be one of: apply, validate (got %q)" .Values.chromadb.sqliteDb.migrationMode) -}}
    {{- end -}}
    {{- $_ := set $sqlitedb "migration_mode" $sqliteMigrationMode -}}
  {{- end -}}
  {{- if gt (len $sqlitedb) 0 -}}
    {{- $_ := set $config "sqlitedb" $sqlitedb -}}
  {{- end -}}
  {{- $circuitBreakerRequestsRaw := .Values.chromadb.circuitBreaker.requests -}}
  {{- if ne $circuitBreakerRequestsRaw nil -}}
    {{- $circuitBreakerRequestsStr := toString $circuitBreakerRequestsRaw -}}
    {{- if not (regexMatch "^-?[0-9]+$" $circuitBreakerRequestsStr) -}}
      {{- fail (printf "chromadb.circuitBreaker.requests must be an integer >= 0 (got %q)" $circuitBreakerRequestsStr) -}}
    {{- end -}}
    {{- $circuitBreakerRequests := atoi $circuitBreakerRequestsStr -}}
    {{- if lt $circuitBreakerRequests 0 -}}
      {{- fail (printf "chromadb.circuitBreaker.requests must be >= 0 (got %d)" $circuitBreakerRequests) -}}
    {{- end -}}
    {{- $_ := set $config "circuit_breaker" (dict "requests" $circuitBreakerRequests) -}}
  {{- end -}}
  {{- with .Values.chromadb.segmentManager.hnswIndexPoolCacheConfig -}}
    {{- if not (kindIs "map" .) -}}
      {{- fail "chromadb.segmentManager.hnswIndexPoolCacheConfig must be a map/object" -}}
    {{- end -}}
    {{- $_ := set $config "segment_manager" (dict "hnsw_index_pool_cache_config" .) -}}
  {{- end -}}
  {{- if and (hasKey .Values.chromadb.telemetry "filters") (not (kindIs "slice" .Values.chromadb.telemetry.filters)) -}}
    {{- fail "chromadb.telemetry.filters must be a list" -}}
  {{- end -}}
{{- end -}}
{{- $otel := dict -}}
{{- if .Values.chromadb.telemetry.enabled -}}
  {{- if not .Values.chromadb.telemetry.endpoint -}}
    {{- fail "chromadb.telemetry.endpoint must be set when chromadb.telemetry.enabled is true" -}}
  {{- end -}}
  {{- $_ := set $otel "service_name" .Values.chromadb.telemetry.serviceName -}}
  {{- $_ := set $otel "endpoint" .Values.chromadb.telemetry.endpoint -}}
{{- end -}}
{{- if and $isV1 .Values.chromadb.telemetry.filters -}}
  {{- $_ := set $otel "filters" .Values.chromadb.telemetry.filters -}}
{{- end -}}
{{- if gt (len $otel) 0 -}}
  {{- $_ := set $config "open_telemetry" $otel -}}
{{- end -}}
{{- with .Values.chromadb.extraConfig -}}
  {{- if not (kindIs "map" .) -}}
    {{- fail "chromadb.extraConfig must be a map/object" -}}
  {{- end -}}
  {{- $config = mergeOverwrite $config . -}}
{{- end -}}
{{- if ne (get $config "port" | int) ($port) -}}
  {{- fail (printf "extraConfig.port (%v) conflicts with chromadb.serverHttpPort (%v) — update serverHttpPort instead" (get $config "port") $.Values.chromadb.serverHttpPort) -}}
{{- end -}}
{{- if ne (get $config "listen_address") .Values.chromadb.serverHost -}}
  {{- fail (printf "extraConfig.listen_address (%s) conflicts with chromadb.serverHost (%s) — update serverHost instead" (get $config "listen_address") .Values.chromadb.serverHost) -}}
{{- end -}}
{{- $config | toYaml -}}
{{- end -}}

{{/*
Get the Chroma auth token header type
*/}}
{{- define "chromadb.auth.token.headerType" -}}
  {{- $headerType := "authorization" }}
  {{- if .Values.chromadb.auth.token.headerType }}
    {{- $headerType = lower .Values.chromadb.auth.token.headerType }}
  {{- end }}
  {{- if eq $headerType "authorization" }}Authorization
  {{- else if or (eq $headerType "x_chroma_token") (eq $headerType "x-chroma-token") }}X-Chroma-Token{{- else }}
    {{- fail (printf "Invalid ChromaDB auth token header type: %s. Allowed values: Authorization, X-Chroma-Token" .Values.chromadb.auth.token.headerType) }}
  {{- end }}
{{- end }}
