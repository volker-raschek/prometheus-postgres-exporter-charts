{{/* vim: set filetype=mustache: */}}

{{/* annotations */}}

{{- define "prometheus-postgres-exporter.podMonitors.http.annotations" -}}
{{ include "prometheus-postgres-exporter.annotations" . }}
{{- if .Values.prometheus.metrics.podMonitor.annotations }}
{{ toYaml .Values.prometheus.metrics.podMonitor.annotations }}
{{- end }}
{{- end }}

{{/* labels */}}

{{- define "prometheus-postgres-exporter.podMonitors.http.labels" -}}
{{ include "prometheus-postgres-exporter.labels" . }}
{{- if .Values.prometheus.metrics.podMonitor.labels }}
{{ toYaml .Values.prometheus.metrics.podMonitor.labels }}
{{- end }}
{{- end }}
