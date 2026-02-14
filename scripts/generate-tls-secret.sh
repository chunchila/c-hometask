#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="${1:-production}"
HOSTNAME="${2:-api.localdev.me}"
SECRET_NAME="${3:-cibus-api-tls}"
CERT_DIR=".certs"

mkdir -p "${CERT_DIR}"

openssl req -x509 -nodes -newkey rsa:2048 -days 365 \
  -keyout "${CERT_DIR}/${HOSTNAME}.key" \
  -out "${CERT_DIR}/${HOSTNAME}.crt" \
  -subj "/CN=${HOSTNAME}/O=cibus"

kubectl -n "${NAMESPACE}" create secret tls "${SECRET_NAME}" \
  --cert="${CERT_DIR}/${HOSTNAME}.crt" \
  --key="${CERT_DIR}/${HOSTNAME}.key" \
  --dry-run=client -o yaml > k8s/tls-secret.yaml

kubectl apply -f k8s/tls-secret.yaml

echo "Created TLS secret ${SECRET_NAME} in namespace ${NAMESPACE}"
