{{/*
Expand the name of the chart.
*/}}
{{- define "aws-auto-eks-cluster.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "aws-auto-eks-cluster.labels" -}}
helm.sh/chart: {{ include "aws-auto-eks-cluster.name" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}
