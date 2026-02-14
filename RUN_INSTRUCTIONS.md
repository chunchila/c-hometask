# Run Instructions

Run all commands from the project root:

`/Users/hatul/Projects/cibus`

## Available scripts

- `scripts/bootstrap-minikube.sh`  
  Starts Minikube (Docker driver), enables ingress, creates `production` namespace.

- `scripts/deploy-local.sh`  
  Builds Docker image, loads it into Minikube, applies app manifests, and waits for rollout.

- `scripts/generate-tls-secret.sh`  
  Generates self-signed cert/key and creates/applies `k8s/tls-secret.yaml`.

- `scripts/install-argocd.sh`  
  Installs ArgoCD into `argocd` namespace and waits for readiness.

## End-to-end steps

### 1) Make scripts executable (once)

```bash
chmod +x scripts/*.sh
```

### 2) Start Minikube + ingress

```bash
./scripts/bootstrap-minikube.sh
```

### 3) Build and deploy the app

```bash
./scripts/deploy-local.sh
```

### 4) Generate and apply TLS secret

```bash
./scripts/generate-tls-secret.sh production api.localdev.me cibus-api-tls
```

### 5) Verify deployed resources

```bash
kubectl get deploy,po,svc,ing -n production
kubectl get secret cibus-api-tls -n production
```

### 6) Test HTTP redirect and HTTPS locally (macOS + Docker driver)

Run and keep this command open in a terminal:

```bash
minikube service ingress-nginx-controller -n ingress-nginx --url
```

It prints two localhost URLs (example ports shown below). Use them like this:

```bash
curl -sSI -H 'Host: api.localdev.me' http://127.0.0.1:64837/healthz
curl -sk -H 'Host: api.localdev.me' https://127.0.0.1:64838/healthz -w '\nHTTP %{http_code}\n'
```

Expected:
- HTTP request returns redirect (`301` or `308`) to HTTPS.
- HTTPS request returns `{"status":"ok"}` and `HTTP 200`.

### 7) Install ArgoCD

```bash
./scripts/install-argocd.sh
```

### 8) Configure and apply ArgoCD Application

1. Edit `argocd/application.yaml` and set:
   - `spec.source.repoURL` to your Git repository URL
   - `spec.source.targetRevision` if your branch is not `main`
2. Apply:

```bash
kubectl apply -f argocd/application.yaml
kubectl get applications.argoproj.io -n argocd
```

## Optional: run API locally without Kubernetes

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r app/requirements.txt
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

Test:

```bash
curl http://localhost:8000/healthz
curl http://localhost:8000/api/v1/message
```
