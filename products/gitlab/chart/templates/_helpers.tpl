{{- define "gitlab.name" -}}{{ .Values.global.namespace }}{{- end }}
{{- define "gitlab.image" -}}{{ .Values.global.imageRegistry }}/{{ .Values.images.gitlab }}{{- end }}
