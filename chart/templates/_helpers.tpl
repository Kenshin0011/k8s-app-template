{{- define "k8s-app.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- define "k8s-app.fullname" -}}
{{- if .Values.fullnameOverride }}{{ .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}{{ else }}{{ printf "%s-%s" .Release.Name (include "k8s-app.name" .) | trunc 63 | trimSuffix "-" }}{{ end }}
{{- end }}
{{- define "k8s-app.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- define "k8s-app.labels" -}}
helm.sh/chart: {{ include "k8s-app.chart" . }}
app.kubernetes.io/name: {{ include "k8s-app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}
{{- define "k8s-app.selectorLabels" -}}
app.kubernetes.io/name: {{ include "k8s-app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
{{- define "k8s-app.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}{{ include "k8s-app.fullname" . }}{{ else }}default{{ end }}
{{- end }}
{{- define "k8s-app.image" -}}
{{- if .Values.image.digest }}{{ printf "%s@%s" .Values.image.repository .Values.image.digest }}{{ else }}{{ printf "%s:%s" .Values.image.repository (default .Chart.AppVersion .Values.image.tag) }}{{ end }}
{{- end }}
