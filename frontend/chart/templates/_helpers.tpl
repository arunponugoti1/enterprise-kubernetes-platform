{{- define "frontend.name" -}}
{{- default "frontend" .Values.nameOverride -}}
{{- end -}}

{{- define "frontend.labels" -}}
app: {{ include "frontend.name" . }}
app.kubernetes.io/name: {{ include "frontend.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{- define "frontend.selectorLabels" -}}
app: {{ include "frontend.name" . }}
{{- end -}}
