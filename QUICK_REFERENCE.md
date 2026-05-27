# Quick Reference Card

## Prerequisites
```bash
# Check CRC is running
crc status

# Set up environment
eval $(crc oc-env)

# Verify access
kubectl get nodes
```

## Quick Start (5 minutes)

### 1. Build Images
```bash
cd /home/redhat/Downloads/openshift/app1
bash build.sh localhost:5000
```

### 2. Deploy
```bash
cd k8s
bash deploy.sh
```

### 3. Access
```
http://task-manager.apps-crc.testing
```

## Test Credentials
```
Username: admin
Password: admin123
```

## Common Commands

### Check Status
```bash
kubectl get pods              # Check pod status
kubectl get svc               # Check services
kubectl get routes            # Check routes
kubectl get pv,pvc            # Check storage
```

### View Logs
```bash
kubectl logs -f deployment/frontend
kubectl logs -f deployment/backend
kubectl logs -f deployment/postgres
```

### Database Access
```bash
kubectl exec -it deployment/postgres -- psql -U postgres -d taskdb
# \dt           - List tables
# SELECT * FROM users;  - View users
```

### Test API
```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"username":"admin","password":"admin123"}'
```

### Port Forward
```bash
kubectl port-forward svc/frontend-service 8080:8080
kubectl port-forward svc/backend-service 3000:3000
kubectl port-forward svc/postgres-service 5432:5432
```

## Troubleshooting

### Pods won't start
```bash
kubectl describe pod <pod-name>  # See why pod is pending
kubectl logs <pod-name>           # Check error logs
```

### Can't reach app
```bash
# Check route
kubectl get routes

# Try port-forward
kubectl port-forward svc/frontend-service 8080:8080
```

### Database not ready
```bash
# Check postgres logs
kubectl logs deployment/postgres

# Verify tables exist
kubectl exec deployment/postgres -- psql -U postgres -d taskdb -c "\dt"
```

## Cleanup
```bash
cd k8s

# Delete everything but keep data
kubectl delete -f 08-route.yaml
kubectl delete -f 07-frontend-deployment.yaml
kubectl delete -f 06-backend-deployment.yaml
kubectl delete -f 04-postgres-deployment.yaml
kubectl delete -f 03-services.yaml
kubectl delete -f 05-postgres-init-configmap.yaml
kubectl delete -f 02-configmap-secret.yaml

# Delete storage (⚠️ LOSES DATA)
kubectl delete -f 01-pv-pvc.yaml
```

## Local Testing (without OpenShift)
```bash
# Run with Docker Compose
bash run-local.sh

# Access at http://localhost:8080
# Stop with: docker-compose down
```

## Key Files
- `README.md` - Main documentation
- `DEPLOYMENT_GUIDE.md` - Complete deployment guide
- `PROJECT_STRUCTURE.md` - Architecture overview
- `k8s/README.md` - Kubernetes-specific docs
- `docker-compose.yml` - Local testing
- `.env.example` - Configuration reference

## API Endpoints (from backend pod)
```
POST   /api/auth/login      - Login with username/password
GET    /api/auth/me         - Get current user info
POST   /api/auth/logout     - Logout
GET    /api/tasks           - List current user's tasks
POST   /api/tasks           - Create new task
DELETE /api/tasks/:id       - Delete task
GET    /health              - Health check
GET    /ready               - Readiness check
```

## Important Notes

✅ **All pods have**:
- Readiness probes (monitors if pod is ready)
- Liveness probes (restarts if unhealthy)

✅ **Storage**:
- PostgreSQL uses PVC for data persistence
- 5Gi storage on node

✅ **Security** (⚠️ development only):
- Credentials in ConfigMap/Secret (base64 encoded)
- No TLS/HTTPS
- Default passwords

✅ **Pod Configuration**:
- Frontend: 1 replica, 8080 port
- Backend: 1 replica, 3000 port
- PostgreSQL: 1 replica, 5432 port (don't scale!)

## Contact & Support
See DEPLOYMENT_GUIDE.md for detailed documentation
