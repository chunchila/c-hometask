# System Architecture

```mermaid
flowchart LR
    user[DeveloperOrTester] --> http80[HTTPPort80]
    user --> https443[HTTPSPort443]
    http80 --> ingress[IngressNginx]
    ingress -->|"redirect to 443"| https443
    https443 --> ingress
    ingress -->|"TLS termination with self-signed cert"| service[ServiceClusterIP]
    service --> app[PythonRestApiPod]
    gitRepo[GitRepository] --> argocd[ArgoCDController]
    argocd -->|"sync manifests"| productionNs[ProductionNamespace]
    productionNs --> ingress
    productionNs --> service
    productionNs --> app
```

## Flow

1. User traffic reaches ingress.
2. Port 80 is redirected to HTTPS 443.
3. Ingress terminates TLS with the Kubernetes TLS secret.
4. Traffic is routed to `cibus-api` service and then to API pods.
5. ArgoCD watches Git and continuously reconciles manifests into `production`.
