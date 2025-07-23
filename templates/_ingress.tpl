{{/* vim: set filetype=mustache: */}}

{{/* annotations */}}

{{- define "prometheus-postgres-exporter.ingress.annotations" -}}
{{ include "prometheus-postgres-exporter.annotations" . }}
{{- if .Values.ingress.annotations }}
{{ toYaml .Values.ingress.annotations }}
{{- end }}
{{- end }}

{{/* labels */}}

{{- define "prometheus-postgres-exporter.ingress.labels" -}}
{{ include "prometheus-postgres-exporter.labels" . }}
{{- if .Values.ingress.labels }}
{{ toYaml .Values.ingress.labels }}
{{- end }}
{{- end }}
