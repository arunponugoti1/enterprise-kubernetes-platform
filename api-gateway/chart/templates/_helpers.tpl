{{- define "api-gateway.name" -}}
{{- default "api-gateway" .Values.nameOverride -}}
{{- end -}}

{{- define "api-gateway.labels" -}}
app: {{ include "api-gateway.name" . }}
app.kubernetes.io/name: {{ include "api-gateway.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{- define "api-gateway.selectorLabels" -}}
app: {{ include "api-gateway.name" . }}
{{- end -}}
