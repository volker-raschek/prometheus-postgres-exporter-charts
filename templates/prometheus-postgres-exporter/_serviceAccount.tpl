{{/* vim: set filetype=mustache: */}}

{{/* annotations */}}

{{- define "prometheus-postgres-exporter.serviceAccount.annotations" -}}
{{- if .Values.serviceAccount.new.annotations }}
{{ toYaml .Values.serviceAccount.new.annotations }}
{{- end }}
{{- end }}

{{/* labels */}}

{{- define "prometheus-postgres-exporter.serviceAccount.labels" -}}
{{- if .Values.serviceAccount.new.labels }}
{{ toYaml .Values.serviceAccount.new.labels }}
{{- end }}
{{- end }}