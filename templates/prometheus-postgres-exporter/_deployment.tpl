{{/* vim: set filetype=mustache: */}}

{{/* annotations */}}

{{- define "prometheus-postgres-exporter.deployment.annotations" -}}
{{ include "prometheus-postgres-exporter.annotations" . }}
{{- if .Values.deployment.annotations }}
{{ toYaml .Values.deployment.annotations }}
{{- end }}
{{- end }}

{{/* envFrom */}}

{{- define "prometheus-postgres-exporter.deployment.envFrom" -}}
{{- $envFrom := dict "envFrom" (.Values.deployment.postgresExporter.envFrom | default (list) ) }}
{{- $secretName := .Values.config.database.existingSecret.secretName -}}
{{- if not .Values.config.database.existingSecret.enabled }}
{{- $secretName = printf "%s-database-env" (include "prometheus-postgres-exporter.fullname" . ) }}
{{- end }}
{{- $envFrom = merge $envFrom (dict "envFrom" (list (dict "secretRef" (dict "name" $secretName)))) }}
{{ toYaml $envFrom }}
{{- end -}}

{{/* image */}}

{{- define "prometheus-postgres-exporter.deployment.images.postgres-exporter.fqin" -}}
{{- $registry := .Values.deployment.postgresExporter.image.registry -}}
{{- $repository := .Values.deployment.postgresExporter.image.repository -}}
{{- $tag := default .Chart.AppVersion .Values.deployment.postgresExporter.image.tag -}}
{{- printf "%s/%s:v%s" $registry $repository $tag -}}
{{- end -}}

{{/* labels */}}

{{- define "prometheus-postgres-exporter.deployment.labels" -}}
{{ include "prometheus-postgres-exporter.labels" . }}
{{- if .Values.deployment.labels }}
{{ toYaml .Values.deployment.labels }}
{{- end }}
{{- end }}

{{/* serviceAccount */}}

{{- define "prometheus-postgres-exporter.deployment.serviceAccount" -}}
{{- if .Values.serviceAccount.existing.enabled -}}
{{- printf "%s" .Values.serviceAccount.existing.serviceAccountName -}}
{{- else -}}
{{- include "prometheus-postgres-exporter.fullname" . -}}
{{- end -}}
{{- end }}

{{/* volumeMounts */}}
{{- define "prometheus-postgres-exporter.deployment.volumeMounts" -}}
{{- $volumeMounts := dict "volumeMounts" (.Values.deployment.postgresExporter.volumeMounts | default (list) ) }}
{{- $volumeMounts = merge $volumeMounts (dict "volumeMounts" (list (dict "name" "config.d" "mountPath" "/etc/prometheus-postgres-exporter/config.d" ))) }}
{{ toYaml $volumeMounts }}
{{- end -}}

{{/* volumes */}}

{{- define "prometheus-postgres-exporter.deployment.volumes" -}}
{{- $volumes := dict "volumes" (.Values.deployment.volumes | default (list) ) }}

{{- if and (not .Values.config.exporterConfig.existingSecret.enabled) (not .Values.config.webConfig.existingSecret.enabled) (not .Values.config.webConfig.secret.webConfig)  }}
{{- $secretName = printf "%s-exporter-config" (include "prometheus-postgres-exporter.fullname" . ) }}
{{- $volumes = merge $volumes (dict "volumes" (list (dict "name" "config.d" "secret" (dict "secretName" $secretName)))) }}
{{- end }}

{{- if and (not .Values.config.exporterConfig.existingSecret.enabled) (or .Values.config.webConfig.existingSecret.enabled .Values.config.webConfig.secret.webConfig) }}
{{- $exporterConfigSecretName = .Values.config.exporterConfig.existingSecret.secretName }}
{{- $webConfigSecretName = .Values.config.webConfig.existingSecret.secretName }}

{{- if -}}

{{- end }}
{{ toYaml $volumes }}
{{- end -}}