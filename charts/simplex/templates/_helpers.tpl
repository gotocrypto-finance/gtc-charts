{{- define "simplex.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "simplex.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{- define "simplex.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "simplex.labels" -}}
helm.sh/chart: {{ include "simplex.chart" . }}
{{ include "simplex.selectorLabels" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "simplex.selectorLabels" -}}
app.kubernetes.io/name: {{ include "simplex.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "simplex.pvcName" -}}
{{- default (printf "%s-data" (include "simplex.fullname" .)) .Values.persistence.existingClaim }}
{{- end }}

{{- define "simplex.secretName" -}}
{{- default (printf "%s-credentials" (include "simplex.fullname" .)) .Values.credentials.existingSecret }}
{{- end }}
