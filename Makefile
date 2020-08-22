TAG ?= druid-exporter:latest

.DEFAULT_GOAL := build

.PHONY: build-exporter
build-exporter:
	docker build -f build/druid_exporter.Dockerfile -t $(TAG) build/

.PHONY: minikube
minikube: build-exporter
	XDG_CONFIG_HOME=${CURDIR} kustomize build --enable_alpha_plugins kustomize/minikube | kubectl apply -f -

.PHONY: gke
gke:
	@echo Don't forget to build and push the image to a docker repo: "make build"
	XDG_CONFIG_HOME=${CURDIR} kustomize build --enable_alpha_plugins kustomize/gke | kubectl apply -f -
