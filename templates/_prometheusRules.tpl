{{/* vim: set filetype=mustache: */}}

{{/* annotations */}}

{{- define "prometheus-postgres-exporter.prometheusRules.annotations" -}}
{{ include "prometheus-postgres-exporter.annotations" . }}
{{- end }}

{{/* labels */}}

{{- define "prometheus-postgres-exporter.prometheusRules.labels" -}}
{{ include "prometheus-postgres-exporter.labels" . }}
{{- end }}
