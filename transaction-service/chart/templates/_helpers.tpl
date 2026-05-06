{{- define "transaction-service.name" -}}
{{- default "transaction-service" .Values.nameOverride -}}
{{- end -}}

{{- define "transaction-service.labels" -}}
app: {{ include "transaction-service.name" . }}
app.kubernetes.io/name: {{ include "transaction-service.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{- define "transaction-service.selectorLabels" -}}
app: {{ include "transaction-service.name" . }}
{{- end -}}
