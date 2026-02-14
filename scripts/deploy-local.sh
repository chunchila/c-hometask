#!/usr/bin/env bash
set -euo pipefail

IMAGE_TAG="${1:-cibus-api:1.0.0}"

docker build -t "${IMAGE_TAG}" .
minikube image load "${IMAGE_TAG}"

kubectl apply -f k8s/namespace-prod.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
kubectl apply -f k8s/ingress.yaml

kubectl rollout status deployment/cibus-api -n production --timeout=180s

echo "Application deployed"
