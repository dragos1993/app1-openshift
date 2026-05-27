# Kubernetes/OpenShift Deployment Guide

This directory contains all Kubernetes/OpenShift manifests for deploying the Task Manager application.

## Files Overview

| File | Purpose |
|------|---------|
| `01-pv-pvc.yaml` | PersistentVolume and PersistentVolumeClaim for PostgreSQL storage |
| `02-configmap-secret.yaml` | ConfigMaps for configuration, Secrets for sensitive data |
| `03-services.yaml` | Service definitions for pod discovery |
| `04-postgres-deployment.yaml` | PostgreSQL deployment with probes |
| `05-postgres-init-configmap.yaml` | Database initialization scripts |
| `06-backend-deployment.yaml` | Backend API deployment with probes |
| `07-frontend-deployment.yaml` | Frontend deployment with probes |
| `08-route.yaml` | OpenShift Route for external access |
| `deploy.sh` | Automated deployment script |

## Deployment Order

**Do not manually apply manifests - use the deploy.sh script!**

```bash
bash deploy.sh
```

The script ensures proper order:
1. ConfigMaps and Secrets
2. PersistentVolume and PersistentVolumeClaim
3. PostgreSQL deployment
4. Backend deployment
5. Frontend deployment
6. Route

## Important Notes for CRC

### Storage Class

CRC provides the `crc-csi-hostpath-provisioner` storage class. The PV manifest references this:

```yaml
storageClassName: crc-csi-hostpath-provisioner
```

If you have a different storage class, update `01-pv-pvc.yaml`.

### Node Affinity

The PV has a placeholder for node affinity:

```yaml
nodeSelectorTerms:
  - matchExpressions:
    - key: kubernetes.io/hostname
      operator: In
      values:
      - crc-xxxxx  # Replace with your CRC node name
```

Get your node name:
```bash
kubectl get nodes
```

Update `01-pv-pvc.yaml` with your actual node name, or remove the nodeAffinity section to let Kubernetes handle it.

### Container Registry

The deployments use `localhost:5000/app1-*:latest` for images.

For CRC, you need to:
1. Build images locally
2. Push to the internal registry

Or change the image references to use your own registry.

## Monitoring Pod Status

### Watch Pod Startup
```bash
watch kubectl get pods
```

### Check Specific Pod Details
```bash
kubectl describe pod <pod-name>
```

### View Pod Events
```bash
kubectl get events --sort-by='.lastTimestamp'
```

## Probes Explained

### Readiness Probe
- Indicates if pod is ready to receive traffic
- If fails, removes pod from service endpoints
- Container continues running

### Liveness Probe
- Indicates if pod is healthy
- If fails repeatedly, Kubernetes restarts the container
- Container doesn't respond = pod will be restarted

### Configuration Parameters

| Parameter | Default | Meaning |
|-----------|---------|---------|
| `initialDelaySeconds` | See each probe | Time to wait after container starts before probing |
| `periodSeconds` | See each probe | How often to probe (in seconds) |
| `timeoutSeconds` | See each probe | How long to wait for response (in seconds) |
| `failureThreshold` | See each probe | Number of failures before action taken |

## Troubleshooting Deployments

### Pods stuck in Pending
```bash
# Check what's preventing scheduling
kubectl describe pod <pod-name>

# Usually storage-related. Check PV/PVC:
kubectl get pv,pvc
kubectl describe pvc postgres-pvc
```

### Pods in CrashLoopBackOff
```bash
# Check logs to see the error
kubectl logs <pod-name>

# Check liveness probe events
kubectl describe pod <pod-name>
```

### Database not initializing
```bash
# PostgreSQL takes time - check logs
kubectl logs deployment/postgres

# Wait longer and check status
kubectl get pod -l app=postgres -w

# Once running, verify database
kubectl exec deployment/postgres -- psql -U postgres -d taskdb -c "SELECT * FROM users;"
```

### Backend can't connect to database
```bash
# Check if postgres service is running
kubectl get svc postgres-service

# Test connectivity from backend pod
kubectl exec deployment/backend -- nslookup postgres-service

# Check backend environment
kubectl exec deployment/backend -- env | grep DB_
```

## Manual Manifest Application

If you need to apply manifests manually:

```bash
# Create storage
kubectl apply -f 01-pv-pvc.yaml

# Create configuration
kubectl apply -f 02-configmap-secret.yaml
kubectl apply -f 05-postgres-init-configmap.yaml

# Create services
kubectl apply -f 03-services.yaml

# Deploy pods
kubectl apply -f 04-postgres-deployment.yaml
kubectl wait --for=condition=ready pod -l app=postgres --timeout=300s
kubectl apply -f 06-backend-deployment.yaml
kubectl wait --for=condition=ready pod -l app=backend --timeout=300s
kubectl apply -f 07-frontend-deployment.yaml

# Create route
kubectl apply -f 08-route.yaml
```

## Cleanup

To delete everything:

```bash
# Delete in reverse order
kubectl delete -f 08-route.yaml
kubectl delete -f 07-frontend-deployment.yaml
kubectl delete -f 06-backend-deployment.yaml
kubectl delete -f 04-postgres-deployment.yaml
kubectl delete -f 03-services.yaml
kubectl delete -f 05-postgres-init-configmap.yaml
kubectl delete -f 02-configmap-secret.yaml

# Keep or delete storage
kubectl delete -f 01-pv-pvc.yaml  # Warning: deletes persistent data!
```

Or use the cleanup script (if available):
```bash
bash cleanup.sh
```

## Resource Requests and Limits

Each pod has configured resources:

### PostgreSQL
- Request: 256Mi memory, 100m CPU
- Limit: 512Mi memory, 500m CPU

### Backend
- Request: 128Mi memory, 50m CPU
- Limit: 256Mi memory, 300m CPU

### Frontend
- Request: 64Mi memory, 25m CPU
- Limit: 128Mi memory, 200m CPU

Adjust these based on your environment and load.

## Accessing Services

### Internal (from pods)
- PostgreSQL: `postgres-service:5432`
- Backend: `backend-service:3000`
- Frontend: `frontend-service:8080`

### External
- Frontend: `http://task-manager.apps-crc.testing` (via Route)

### Port Forward (for local access)
```bash
kubectl port-forward svc/backend-service 3000:3000
kubectl port-forward svc/frontend-service 8080:8080
kubectl port-forward svc/postgres-service 5432:5432
```

## Advanced: Checking Image Pull Policy

Deployments use `imagePullPolicy: IfNotPresent`, which means:
- Use local image if it exists
- Only pull from registry if local doesn't exist

If images need to be updated:
```bash
kubectl set image deployment/frontend frontend=localhost:5000/app1-frontend:v2.0
kubectl set image deployment/backend backend=localhost:5000/app1-backend:v2.0
```

## Advanced: Scaling Pods

Currently, deployments use `replicas: 1`. To scale:

```bash
kubectl scale deployment frontend --replicas=3
kubectl scale deployment backend --replicas=2
# Don't scale postgres (database)!
```

## Advanced: Pod Resource Monitoring

Check actual resource usage:
```bash
kubectl top pods
kubectl top nodes
```

Requires metrics-server to be installed (usually present in CRC).

## Validation

After deployment, validate everything:

```bash
# All pods should be Running and Ready
kubectl get pods

# All services should have endpoints
kubectl get svc

# Route should be created
kubectl get routes

# Try accessing the application
curl http://task-manager.apps-crc.testing
```

## Next Steps

See the main [README.md](../README.md) for application usage and testing instructions.
