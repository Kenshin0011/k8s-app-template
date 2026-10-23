# k8s-app-template

Reusable Helm chart for deploying a containerized application to Kubernetes.

This is application-focused: Deployment, Service, probes, resources, security context, HPA, PDB, Ingress and optional NetworkPolicy. Databases and cluster infrastructure stay outside the chart.

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
