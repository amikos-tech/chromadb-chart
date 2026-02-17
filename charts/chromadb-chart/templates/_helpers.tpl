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
