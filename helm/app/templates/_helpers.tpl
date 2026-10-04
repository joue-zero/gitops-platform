{{/*
Chart name, truncated to the 63-character DNS label limit.
*/}}
{{- define "gitops-app.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Fully qualified resource name. Reuses the release name when it already contains the chart name.
*/}}
{{- define "gitops-app.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Chart name and version for the helm.sh/chart label.
*/}}
{{- define "gitops-app.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Selector labels. Immutable once a Deployment exists, so keep this set minimal.
*/}}
{{- define "gitops-app.selectorLabels" -}}
app.kubernetes.io/name: {{ include "gitops-app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Common labels applied to every resource.
*/}}
{{- define "gitops-app.labels" -}}
helm.sh/chart: {{ include "gitops-app.chart" . }}
{{ include "gitops-app.selectorLabels" . }}
app.kubernetes.io/version: {{ default .Chart.AppVersion .Values.image.tag | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: gitops-platform
{{- end }}

{{/*
ServiceAccount name.
*/}}
{{- define "gitops-app.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "gitops-app.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Container image reference. Fails fast with a clear message when no repository is configured.
*/}}
{{- define "gitops-app.image" -}}
{{- printf "%s:%s" (required "image.repository is required" .Values.image.repository) (default .Chart.AppVersion .Values.image.tag) }}
{{- end }}
