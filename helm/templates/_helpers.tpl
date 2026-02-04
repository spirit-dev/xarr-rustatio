{{/*
Expand the name of the chart.
*/}}
{{- define "rustatio.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "rustatio.fullname" -}}
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
Create chart name and version as used by the chart label.
*/}}
{{- define "rustatio.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "rustatio.labels" -}}
helm.sh/chart: {{ include "rustatio.chart" . }}
{{ include "rustatio.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "rustatio.selectorLabels" -}}
app.kubernetes.io/name: {{ include "rustatio.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "rustatio.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "rustatio.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create the name of the secret to use for AUTH_TOKEN
*/}}
{{- define "rustatio.secretName" -}}
{{- default (include "rustatio.fullname" .) .Values.auth.existingSecret }}
{{- end }}

{{/*
Get AUTH_TOKEN from secret
*/}}
{{- define "rustatio.authToken" -}}
{{- if .Values.auth.existingSecret }}
{{- print "$(AUTH_TOKEN)" }}
{{- else if .Values.auth.token }}
{{- .Values.auth.token }}
{{- end }}
{{- end }}

{{/*
VPN enabled check
*/}}
{{- define "rustatio.vpnEnabled" -}}
{{- if and .Values.vpn.enabled .Values.vpn.gluetun.enabled -}}
true
{{- end -}}
{{- end }}

{{/*
PVC name for data
*/}}
{{- define "rustatio.dataPvcName" -}}
{{- if .Values.persistence.data.existingClaim }}
{{- .Values.persistence.data.existingClaim }}
{{- else }}
{{- printf "%s-data" (include "rustatio.fullname" .) }}
{{- end }}
{{- end }}

{{/*
PVC name for torrents
*/}}
{{- define "rustatio.torrentsPvcName" -}}
{{- if .Values.persistence.torrents.existingClaim }}
{{- .Values.persistence.torrents.existingClaim }}
{{- else }}
{{- printf "%s-torrents" (include "rustatio.fullname" .) }}
{{- end }}
{{- end }}
