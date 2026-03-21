{{/*
  judge-engine.name
  Returns the chart name, truncated to 63 chars (K8s name limit)
  Example: "judge-engine"
*/}}
{{- define "judge-engine.name" -}}
{{- .Chart.Name | trunc 63 | trimSuffix "-" }}
{{- end }}


{{/*
  judge-engine.fullname
  Returns Release.Name + Chart.Name as resource name prefix
  Example: helm install myapp ./chart  →  "myapp-judge-engine"
*/}}
{{- define "judge-engine.fullname" -}}
{{- printf "%s-%s" .Release.Name .Chart.Name | trunc 63 | trimSuffix "-" }}
{{- end }}


{{/*
  judge-engine.labels
  Common labels applied to ALL resources
  Includes selectorLabels + chart metadata
*/}}
{{- define "judge-engine.labels" -}}
helm.sh/chart: {{ include "judge-engine.name" . }}-{{ .Chart.Version }}
{{ include "judge-engine.selectorLabels" . }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}


{{/*
  judge-engine.selectorLabels
  Labels used in Deployment matchLabels (must not change after creation)
  Only 2 labels — matchLabels must be a subset of pod labels
*/}}
{{- define "judge-engine.selectorLabels" -}}
app.kubernetes.io/name: {{ include "judge-engine.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}