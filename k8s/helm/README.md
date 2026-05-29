# app1 Helm chart

This Helm chart packages the existing OpenShift manifests from `k8s/` into a reusable chart.

## Deploy with Helm

1. Build or push your Docker Hub images from the app repo.
2. Install the chart from this directory:

```bash
cd /home/redhat/Downloads/openshift/app1/k8s/helm
helm install app1 . --namespace app1 --create-namespace
```

3. To upgrade after image/tag changes:

```bash
helm upgrade app1 . --namespace app1
```

## Values

The chart supports:
- `postgres.image.repository` and `postgres.image.tag`
- `backend.image.repository` and `backend.image.tag`
- `frontend.image.repository` and `frontend.image.tag`
- `secret.dbPassword` and `secret.jwtSecret`
- `route.host`, `route.frontendPath`, `route.apiPath`

## Argo CD deployment

If you want Argo CD to manage this chart, use the ApplicationSet manifest from `k8s/argocd-applicationset.yaml`.

The ApplicationSet deploys the chart from a Git repo path of `services/helm` and automatically syncs when `values.yml` changes.

## Notes

OpenShift Routes are included in this chart, so the route host is configurable through `route.host`.

The PostgreSQL deployment mounts `postgres-pvc` and uses the `postgres-init-script` ConfigMap for initial schema creation.
