---

{{/* annotations */}}

{{- define "prometheus-postgres-exporter.pod.annotations" -}}
{{ include "prometheus-postgres-exporter.annotations" . }}
{{- end }}

{{/* labels */}}

{{- define "prometheus-postgres-exporter.pod.labels" -}}
{{ include "prometheus-postgres-exporter.labels" . }}
{{- end }}

{{- define "prometheus-postgres-exporter.pod.selectorLabels" -}}
{{ include "prometheus-postgres-exporter.pod.labels" . }}
{{- end }}