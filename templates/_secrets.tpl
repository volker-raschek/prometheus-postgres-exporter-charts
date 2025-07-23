{{/* vim: set filetype=mustache: */}}

{{/* annotations */}}

{{- define "prometheus-postgres-exporter.secrets.database.annotations" -}}
{{ include "prometheus-postgres-exporter.annotations" . }}
{{- if .Values.config.database.secret.annotations }}
{{ toYaml .Values.config.database.secret.annotations }}
{{- end }}
{{- end }}

{{- define "prometheus-postgres-exporter.secrets.exporterConfig.annotations" -}}
{{ include "prometheus-postgres-exporter.annotations" . }}
{{- if .Values.config.exporterConfig.secret.annotations }}
{{ toYaml .Values.config.exporterConfig.secret.annotations }}
{{- end }}
{{- end }}

{{- define "prometheus-postgres-exporter.secrets.webConfig.annotations" -}}
{{ include "prometheus-postgres-exporter.annotations" . }}
{{- if .Values.config.webConfig.secret.annotations }}
{{ toYaml .Values.config.webConfig.secret.annotations }}
{{- end }}
{{- end }}

{{/* labels */}}

{{- define "prometheus-postgres-exporter.secrets.database.labels" -}}
{{ include "prometheus-postgres-exporter.labels" . }}
{{- if .Values.config.database.secret.labels }}
{{ toYaml .Values.config.database.secret.labels }}
{{- end }}
{{- end }}

{{- define "prometheus-postgres-exporter.secrets.exporterConfig.labels" -}}
{{ include "prometheus-postgres-exporter.labels" . }}
{{- if .Values.config.exporterConfig.secret.labels }}
{{ toYaml .Values.config.exporterConfig.secret.labels }}
{{- end }}
{{- end }}


{{- define "prometheus-postgres-exporter.secrets.webConfig.labels" -}}
{{ include "prometheus-postgres-exporter.labels" . }}
{{- if .Values.config.webConfig.secret.labels }}
{{ toYaml .Values.config.webConfig.secret.labels }}
{{- end }}
{{- end }}
