# Senior DevOps Assignment - Cibus

This repository implements the full assignment:
- Minikube local environment (Docker driver)
- Python 3.10+ REST API in a non-root production Docker image
- NGINX Ingress with HTTP->HTTPS redirect and TLS termination
- ArgoCD GitOps deployment into `production` namespace

## Repository Contents

- `app/main.py`: FastAPI service (`/healthz`, `/api/v1/message`)
- `app/requirements.txt`: Python dependencies
- `Dockerfile`: Non-root production container image
- `k8s/`: Namespace, Deployment, Service, Ingress, TLS secret manifest, kustomization
- `argocd/application.yaml`: ArgoCD Application definition
- `terraform/main.tf`: Terraform for cluster namespaces after Minikube init
- `scripts/`: Bootstrap/install/deploy helper scripts
- `docs/architecture.md`: High-level architecture diagram

## Prerequisites

Install the following CLIs:
- Docker
- `minikube`
- `kubectl`
- `terraform`
- `argocd` (optional for CLI management)
- `openssl`

## 1) Local Environment (Minikube + Docker driver)

Step-by-step:

1. Start Minikube and enable ingress:
   - `./scripts/bootstrap-minikube.sh`
2. Verify cluster and ingress:
   - `kubectl get nodes`
   - `kubectl get pods -n ingress-nginx`
3. Confirm `production` namespace:
   - `kubectl get ns production`

What this does:
- Creates local Kubernetes using Docker as runtime.
- Enables ingress-nginx controller.
- Prepares `production` namespace for application resources.

## 2) Application Development (Python API)

The API is implemented with FastAPI:
- `GET /healthz` -> health signal for probes
- `GET /api/v1/message` -> sample business endpoint

Run locally without Docker:

1. `python3 -m venv .venv`
2. `source .venv/bin/activate`
3. `pip install -r app/requirements.txt`
4. `uvicorn app.main:app --host 0.0.0.0 --port 8000`
5. `curl http://localhost:8000/healthz`

Expected:
- HTTP 200 with `{"status":"ok"}`

## 3) Containerization (non-root production image)

Build image:
- `docker build -t cibus-api:1.0.0 .`

Why this is production-ready:
- Uses slim Python base image.
- Installs exact dependencies from `requirements.txt`.
- Runs as non-root user (`appuser`).
- Uses `gunicorn` + `uvicorn` worker for serving.

Validate non-root user:
- `docker run --rm cibus-api:1.0.0 id`
- Ensure UID is not `0`.

## 4) Deploy app resources to Kubernetes

Use helper script:
- `./scripts/deploy-local.sh`

Or apply manually:
1. `kubectl apply -f k8s/namespace-prod.yaml`
2. `kubectl apply -f k8s/deployment.yaml`
3. `kubectl apply -f k8s/service.yaml`
4. `kubectl apply -f k8s/ingress.yaml`

Health checks:
- `kubectl get deploy,po,svc,ing -n production`
- `kubectl get endpoints -n production cibus-api`

## 5) Ingress HTTPS enforcement + TLS secret

Generate self-signed cert and create Kubernetes TLS secret:
- `./scripts/generate-tls-secret.sh production api.localdev.me cibus-api-tls`

This script:
1. Generates self-signed cert/key in `.certs/`.
2. Creates `k8s/tls-secret.yaml`.
3. Applies the secret to the cluster.

Validate redirect and TLS:
1. `MINIKUBE_IP=$(minikube ip)`
2. `curl -I --resolve api.localdev.me:80:${MINIKUBE_IP} http://api.localdev.me/healthz`
3. `curl -k --resolve api.localdev.me:443:${MINIKUBE_IP} https://api.localdev.me/healthz`

Expected:
- HTTP call returns `301` or `308` redirect to HTTPS.
- HTTPS call returns `200`.

## 6) Install ArgoCD

Install:
- `./scripts/install-argocd.sh`

Verify:
- `kubectl get pods -n argocd`

Optional UI access:
- `kubectl port-forward svc/argocd-server -n argocd 8080:443`

## 7) GitOps Application

1. Push this repository to your Git remote.
2. Update `argocd/application.yaml`:
   - `repoURL` to your repository URL.
   - `targetRevision` if branch is not `main`.
3. Apply ArgoCD Application:
   - `kubectl apply -f argocd/application.yaml`
4. Verify status:
   - `kubectl get applications.argoproj.io -n argocd`

Auto-sync behavior enabled:
- `prune: true` (remove obsolete resources)
- `selfHeal: true` (reconcile drift)

## 8) Terraform Manifests (post-init resource management)

Terraform is provided in `terraform/main.tf` for namespace management:

1. `cd terraform`
2. `terraform init`
3. `terraform plan`
4. `terraform apply`

The provider uses:
- kubeconfig at `~/.kube/config`
- context `minikube`

## Required Outputs Mapping

1. System architecture diagram:
   - `docs/architecture.md`
2. Code repository includes:
   - Python web service (`app/`)
   - Kubernetes YAML manifests (`k8s/`)
   - Terraform manifests (`terraform/`)
   - Ingress + ArgoCD Application definitions
3. Instructions file:
   - `README.md` (this document)

## Troubleshooting

- Ingress not ready:
  - `kubectl get pods -n ingress-nginx`
  - Wait until controller pod is Running.
- TLS secret missing:
  - Re-run `./scripts/generate-tls-secret.sh`.
- ArgoCD app OutOfSync:
  - Check repo URL/path/branch in `argocd/application.yaml`.
- Image pull issues:
  - Re-run `minikube image load cibus-api:1.0.0`.
