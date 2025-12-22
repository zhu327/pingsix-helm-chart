{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "apisix.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "apisix.fullname" -}}
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
{{- define "apisix.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "apisix.labels" -}}
helm.sh/chart: {{ include "apisix.chart" . }}
{{ include "apisix.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "apisix.selectorLabels" -}}
{{- if .Values.service.labelsOverride }}
{{- tpl (.Values.service.labelsOverride | toYaml) . }}
{{- else }}
app.kubernetes.io/name: {{ include "apisix.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "apisix.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "apisix.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Renders a value that contains template.
Usage:
{{ include "apisix.tplvalues.render" ( dict "value" .Values.path.to.the.Value "context" $) }}
*/}}
{{- define "apisix.tplvalues.render" -}}
    {{- if typeIs "string" .value }}
        {{- tpl .value .context }}
    {{- else }}
        {{- tpl (.value | toYaml) .context }}
    {{- end }}
{{- end -}}

{{/*
Scheme to use while connecting etcd
*/}}
{{- define "apisix.etcd.auth.scheme" -}}
{{- if .Values.etcd.auth.tls.enabled }}
{{- "https" }}
{{- else }}
{{- "http" }}
{{- end }}
{{- end }}

{{/*
Parse listener address and return port
Usage:
{{ include "apisix.listener.port" "0.0.0.0:8080" }}
*/}}
{{- define "apisix.listener.port" -}}
{{- $parts := split ":" . }}
{{- last $parts }}
{{- end -}}

{{/*
Parse listener address and return IP
Usage:
{{ include "apisix.listener.ip" "0.0.0.0:8080" }}
*/}}
{{- define "apisix.listener.ip" -}}
{{- $parts := split ":" . }}
{{- if gt (len $parts) 2 }}
{{- /* IPv6 address like [::]:8080 */ -}}
{{- $joined := join ":" (initial $parts) }}
{{- trim $joined "[]" }}
{{- else }}
{{- /* IPv4 address like 0.0.0.0:8080 */ -}}
{{- first $parts }}
{{- end }}
{{- end -}}

{{/*
Get etcd host list based on priority
Priority: ingress-controller > built-in etcd > external etcd
*/}}
{{- define "apisix.etcd.hosts" -}}
{{- if (index .Values "ingress-controller" "enabled") }}
{{- $ingressEtcdPort := index .Values "ingress-controller" "etcd" "port" | default "12379" }}
{{- printf "http://%s:%s" (include "apisix.fullname" .) $ingressEtcdPort }}
{{- else if .Values.etcd.enabled }}
{{- $etcdScheme := include "apisix.etcd.auth.scheme" . }}
{{- if .Values.etcd.fullnameOverride }}
{{- printf "%s://%s:%d" $etcdScheme .Values.etcd.fullnameOverride (.Values.etcd.service.port | int) }}
{{- else }}
{{- printf "%s://%s-etcd.%s.svc.cluster.local:%d" $etcdScheme .Release.Name .Release.Namespace (.Values.etcd.service.port | int) }}
{{- end }}
{{- else if .Values.externalEtcd.host }}
{{- range .Values.externalEtcd.host }}
{{- . }}
{{- end }}
{{- end }}
{{- end -}}

{{/*
Check if etcd is enabled (any of the three options)
*/}}
{{- define "apisix.etcd.enabled" -}}
{{- if or (index .Values "ingress-controller" "enabled") .Values.etcd.enabled .Values.externalEtcd.host }}
{{- "true" }}
{{- else }}
{{- "false" }}
{{- end }}
{{- end -}}
