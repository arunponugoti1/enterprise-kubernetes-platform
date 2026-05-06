{{/*
Expand the name of the chart.
*/}}
{{- define "SERVICE_NAME.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "SERVICE_NAME.labels" -}}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
app.kubernetes.io/name: {{ include "SERVICE_NAME.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Values.image.tag | default .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels — used by Service and Deployment matchLabels.
*/}}
{{- define "SERVICE_NAME.selectorLabels" -}}
app.kubernetes.io/name: {{ include "SERVICE_NAME.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
