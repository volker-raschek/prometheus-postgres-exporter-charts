---

{{/* annotations */}}

{{- define "prometheus-postgres-exporter.pod.annotations" -}}
{{ include "prometheus-postgres-exporter.annotations" . }}

# The following annotations are required to trigger a rolling update. Further information can be found in the official
# documentation of helm:
#
#   https://helm.sh/docs/howto/charts_tips_and_tricks/#automatically-roll-deployments
#

{{/* database */}}
{{- if and .Values.config.database.existingSecret.enabled .Values.config.database.existingSecret.secretName }}
{{- $secret := default (dict "data" (dict)) (lookup "v1" "Secret" .Release.Namespace .Values.config.database.existingSecret.secretName ) }}
checksum/secret-database: {{ print $secret.spec | sha256sum }}
{{- else }}
checksum/secret-database: {{ include (print $.Template.BasePath "/prometheus-postgres-exporter/secretDatabase.yaml") . | sha256sum }}
{{- end }}

{{/* exporter config */}}
{{- if and .Values.config.exporterConfig.existingSecret.enabled .Values.config.exporterConfig.existingSecret.secretName }}
{{- $secret := default (dict "data" (dict)) (lookup "v1" "Secret" .Release.Namespace .Values.config.exporterConfig.existingSecret.secretName ) }}
checksum/secret-exporter-config: {{ print $secret.spec | sha256sum }}
{{- else }}
checksum/secret-exporter-config: {{ include (print $.Template.BasePath "/prometheus-postgres-exporter/secretExporterConfig.yaml") . | sha256sum }}
{{- end }}

{{/* web config */}}
{{- if and .Values.config.webConfig.existingSecret.enabled .Values.config.webConfig.existingSecret.secretName }}
{{- $secret := default (dict "data" (dict)) (lookup "v1" "Secret" .Release.Namespace .Values.config.webConfig.existingSecret.secretName ) }}
checksum/secret-web-config: {{ print $secret.spec | sha256sum }}
{{- else }}
checksum/secret-web-config: {{ include (print $.Template.BasePath "/prometheus-postgres-exporter/secretWebConfig.yaml") . | sha256sum }}
{{- end }}

{{- end }}

{{/* labels */}}

{{- define "prometheus-postgres-exporter.pod.labels" -}}
{{ include "prometheus-postgres-exporter.labels" . }}
{{- end }}

{{- define "prometheus-postgres-exporter.pod.selectorLabels" -}}
{{ include "prometheus-postgres-exporter.selectorLabels" . }}
{{- end }}