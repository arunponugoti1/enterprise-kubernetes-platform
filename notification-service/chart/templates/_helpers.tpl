{{- define "notification-service.name" -}}
{{- default "notification-service" .Values.nameOverride -}}
{{- end -}}

{{- define "notification-service.labels" -}}
app: {{ include "notification-service.name" . }}
app.kubernetes.io/name: {{ include "notification-service.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{- define "notification-service.selectorLabels" -}}
app: {{ include "notification-service.name" . }}
{{- end -}}
