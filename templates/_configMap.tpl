{{/* vim: set filetype=mustache: */}}

{{/* annotations */}}

{{- define "prometheus-postgres-exporter.configMap.grafanaDashboards.postgresExporter.annotations" -}}
{{ include "prometheus-postgres-exporter.annotations" . }}
{{- if .Values.grafana.dashboards.postgresExporter.annotations }}
{{ toYaml .Values.grafana.dashboards.postgresExporter.annotations }}
{{- end }}
{{- end }}

{{/* labels */}}

{{- define "prometheus-postgres-exporter.configMap.grafanaDashboards.postgresExporter.labels" -}}
{{ include "prometheus-postgres-exporter.labels" . }}
{{- if .Values.grafana.dashboards.postgresExporter.labels }}
{{ toYaml .Values.grafana.dashboards.postgresExporter.labels }}
{{- end }}
{{ toYaml .Values.grafana.dashboardDiscoveryLabels }}
{{- end }}