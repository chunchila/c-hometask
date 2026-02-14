#!/usr/bin/env bash
set -euo pipefail

PROFILE="${MINIKUBE_PROFILE:-minikube}"

echo "Starting Minikube profile: ${PROFILE}"
minikube start --driver=docker -p "${PROFILE}"

echo "Enabling ingress addon"
minikube addons enable ingress -p "${PROFILE}"

echo "Creating production namespace"
kubectl create namespace production --dry-run=client -o yaml | kubectl apply -f -

echo "Waiting for ingress controller"
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=180s

echo "Bootstrap completed"
