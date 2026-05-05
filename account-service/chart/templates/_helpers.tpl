{{- define "account-service.name" -}}
{{- default "account-service" .Values.nameOverride -}}
{{- end -}}

{{- define "account-service.labels" -}}
app: {{ include "account-service.name" . }}
app.kubernetes.io/name: {{ include "account-service.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{- define "account-service.selectorLabels" -}}
app: {{ include "account-service.name" . }}
{{- end -}}
