{{/* vim: set filetype=mustache: */}}

{{/* annotations */}}

{{- define "prometheus-postgres-exporter.serviceMonitors.http.annotations" -}}
{{ include "prometheus-postgres-exporter.annotations" . }}
{{- if .Values.prometheus.metrics.serviceMonitor.annotations }}
{{ toYaml .Values.prometheus.metrics.serviceMonitor.annotations }}
{{- end }}
{{- end }}

{{/* labels */}}

{{- define "prometheus-postgres-exporter.serviceMonitors.http.labels" -}}
{{ include "prometheus-postgres-exporter.labels" . }}
{{- if .Values.prometheus.metrics.serviceMonitor.labels }}
{{ toYaml .Values.prometheus.metrics.serviceMonitor.labels }}
{{- end }}
{{- end }}

{{- define "prometheus-postgres-exporter.serviceMonitors.http.selectorLabels" -}}
{{ include "prometheus-postgres-exporter.selectorLabels" . }}
{{/* Add label to select the correct service via `selector.matchLabels` of the serviceMonitor resource. */}}
app.kubernetes.io/service-name: http
{{- end }}