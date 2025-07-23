{{/* vim: set filetype=mustache: */}}

{{/* annotations */}}

{{- define "prometheus-postgres-exporter.services.http.annotations" -}}
{{ include "prometheus-postgres-exporter.annotations" . }}
{{- if .Values.services.http.annotations }}
{{ toYaml .Values.services.http.annotations }}
{{- end }}
{{- end }}

{{/* labels */}}

{{- define "prometheus-postgres-exporter.services.http.labels" -}}
{{ include "prometheus-postgres-exporter.labels" . }}
{{/* Add label to select the correct service via `selector.matchLabels` of the serviceMonitor resource. */}}
app.kubernetes.io/service-name: http
{{- if .Values.services.http.labels }}
{{ toYaml .Values.services.http.labels }}
{{- end }}
{{- end }}

{{/* names */}}

{{- define "prometheus-postgres-exporter.services.http.name" -}}
{{- if .Values.services.http.enabled -}}
{{ include "prometheus-postgres-exporter.fullname" . }}-http
{{- end -}}
{{- end -}}