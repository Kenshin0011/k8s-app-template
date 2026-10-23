# k8s-app-template

Reusable Helm chart for deploying a containerized application to Kubernetes.

This is application-focused: Deployment, Service, probes, resources, security context, HPA, PDB, Ingress and optional NetworkPolicy. Databases and cluster infrastructure stay outside the chart.

## Kubernetes architecture

```mermaid
flowchart LR
    User[Client] --> DNS[DNS]
    DNS --> Ingress[Ingress]
    Ingress --> Service[Service<br/>ClusterIP]
    Service --> PodA[Pod 1<br/>Application container]
    Service --> PodB[Pod 2<br/>Application container]

    Deployment[Deployment] --> PodA
    Deployment --> PodB
    HPA[HPA<br/>optional] -. scales .-> Deployment
    PDB[PDB<br/>optional] -. protects .-> PodA
    PDB -. protects .-> PodB

    ConfigMap[ConfigMap<br/>optional] -. config .-> PodA
    ConfigMap -. config .-> PodB
    Secret[SealedSecret<br/>encrypted in Git] --> SecretRuntime[Secret<br/>created in cluster]
    SecretRuntime -. env .-> PodA
    SecretRuntime -. env .-> PodB

    Policy[NetworkPolicy<br/>optional] -. controls traffic .-> PodA
    Policy -. controls traffic .-> PodB
```

### Resource responsibilities

| Resource | Responsibility | Default |
| --- | --- | --- |
| Ingress | External HTTP/HTTPS entry point and host/path routing | Disabled |
| Service | Stable internal endpoint for Pods | Enabled |
| Deployment | Rolling updates and replica management | Enabled |
| Pod | Runs the application container and health probes | Enabled |
| HPA | Scales replicas from CPU utilization | Disabled |
| PDB | Limits voluntary disruption during maintenance | Enabled |
| ConfigMap | Non-sensitive application configuration | Disabled |
| SealedSecret | Encrypted configuration committed to Git and decrypted in-cluster | Disabled |
| NetworkPolicy | Optional ingress/egress traffic restrictions | Disabled |

Ingress and HPA are intentionally disabled by default because their exact behavior depends on the cluster's ingress controller and metrics server.

## Deployment flow

```mermaid
flowchart TD
    A[Application repository] --> B[Build container image]
    B --> C[Push image to registry]
    C --> D{Environment}
    D -->|Development| E[environments/dev-values.yaml]
    D -->|Production| F[environments/production-values.yaml]
    E --> G[helm upgrade --install]
    F --> G
    G --> H[Helm renders Kubernetes resources]
    H --> I[Deployment rollout]
    I --> J{Readiness probe passes?}
    J -->|No| K[Pod stays out of Service traffic]
    K --> I
    J -->|Yes| L[Service routes traffic]
    L --> M{HPA enabled?}
    M -->|Yes| N[Scale replicas from metrics]
    M -->|No| O[Keep configured replica count]
    N --> P[Monitor and rollback if needed]
    O --> P
```

The normal path is: build an immutable image, select environment-specific values, render and apply the Helm release, then let probes control traffic during rollout. For production, use an image digest instead of a mutable tag.

## Quick start

```bash
helm lint chart
helm template my-app chart --namespace my-app
helm upgrade --install my-app chart \
  --namespace my-app --create-namespace \
  --set image.repository=ghcr.io/your-org/your-app \
  --set image.tag=1.0.0
```

For production, prefer an immutable image digest:

```bash
helm upgrade --install my-app chart \
  --namespace my-app --create-namespace \
  -f environments/production-values.yaml \
  --set image.digest=sha256:...
```

The default chart expects port `8080` and `GET /health`. Override `container.port`, `service.port`, and probe paths when needed.

## Useful commands

```bash
make lint
make template
make install
make uninstall
```

## Sealed Secrets

Install the Sealed Secrets controller once per cluster, then create an encrypted secret with `kubeseal`:

```bash
kubectl create secret generic my-app-secret \
  --from-literal=DATABASE_URL='postgres://...' \
  --namespace my-app \
  --dry-run=client -o json \
  | kubeseal --format yaml > /tmp/my-app-sealed-secret.yaml
```

Copy the generated `spec.encryptedData` into an environment values file and enable the feature:

```yaml
secret:
  name: my-app-secret

sealedSecret:
  enabled: true
  encryptedData:
    DATABASE_URL: Ag...
```

The encrypted values can be committed to Git, but plaintext values must never be committed. The controller creates the regular Kubernetes Secret that the Deployment references. Do not install the controller as part of this application chart; it is a cluster-level component.
