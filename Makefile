.DEFAULT_GOAL := build

.PHONY: build
build:
	docker build -f build/druid_exporter.Dockerfile -t druid-exporer:latest build/

.PHONY: minikube
minikube: build
	XDG_CONFIG_HOME=${CURDIR} kustomize build --enable_alpha_plugins kustomize/minikube | kubectl apply -f -

.PHONY: gke
gke: build
	XDG_CONFIG_HOME=${CURDIR} kustomize build --enable_alpha_plugins kustomize/gke | kubectl apply -f -
