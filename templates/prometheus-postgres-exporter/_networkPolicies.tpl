{{/* vim: set filetype=mustache: */}}

{{/* annotations */}}

{{- define "prometheus-postgres-exporter.networkPolicies.annotations" -}}
{{ include "prometheus-postgres-exporter.annotations" .context }}
{{- if .networkPolicy.annotations }}
{{ toYaml .networkPolicy.annotations }}
{{- end }}
{{- end }}

{{/* labels */}}

{{- define "prometheus-postgres-exporter.networkPolicies.labels" -}}
{{ include "prometheus-postgres-exporter.labels" .context }}
{{- if .networkPolicy.labels }}
{{ toYaml .networkPolicy.labels }}
{{- end }}
{{- end }}
