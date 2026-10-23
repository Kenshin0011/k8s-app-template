# k8s-app-template

Reusable Helm chart for deploying a containerized application to Kubernetes.

This is application-focused: Deployment, Service, probes, resources, security context, HPA, PDB, Ingress and optional NetworkPolicy. Databases and cluster infrastructure stay outside the chart.

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

Secrets are referenced rather than stored in Git. Set `secret.existingSecret` to an existing Kubernetes Secret; its keys will be exposed as environment variables.
