# Complete Deployment Guide for Task Manager on OpenShift CRC

This guide covers everything you need to deploy the Task Manager application on your OpenShift CRC cluster.

## Prerequisites Checklist

- [ ] OpenShift CRC is running (`crc status`)
- [ ] OpenShift CLI installed (`oc version` or `kubectl version`)
- [ ] Docker is installed (`docker --version`)
- [ ] You have access to the CRC cluster (`oc whoami` or `kubectl auth can-i create deployments`)
- [ ] Storage class available (`kubectl get sc`)
  - Required: `crc-csi-hostpath-provisioner` (default in CRC)

## Step-by-Step Deployment

### Step 1: Verify CRC Environment

```bash
# Check CRC status
crc status

# Set up CRC environment
eval $(crc oc-env)

# Verify cluster access
kubectl get nodes
kubectl get sc
```

Expected output should show:
- At least one node running
- Storage class: `crc-csi-hostpath-provisioner`

### Step 2: Navigate to Project Directory

```bash
cd /home/redhat/Downloads/openshift/app1
```

### Step 3: (Optional) Test Locally with Docker Compose

Before deploying to OpenShift, test the application locally:

```bash
bash run-local.sh
```

This will:
- Build all Docker images
- Start containers using docker-compose
- Make application available at `http://localhost:8080`

To stop:
```bash
docker-compose down
```

### Step 4: Build Docker Images

Build images for OpenShift deployment:

```bash
bash build.sh localhost:5000
```

This will build three images:
- `localhost:5000/app1-frontend:latest`
- `localhost:5000/app1-backend:latest`
- `localhost:5000/app1-postgres:latest`

**Note**: Images are built locally and referenced by the deployments as `imagePullPolicy: IfNotPresent`.

### Step 5: Deploy to OpenShift

Deploy all components:

```bash
cd k8s
bash deploy.sh
```

The deployment script will:
1. Create ConfigMaps and Secrets
2. Create PersistentVolume and PersistentVolumeClaim
3. Deploy PostgreSQL
4. Deploy Backend API
5. Deploy Frontend
6. Create Route for external access
7. Wait for all pods to become ready

**Expected deployment time**: 1-3 minutes depending on CRC performance.

### Step 6: Verify Deployment

Check pod status:
```bash
kubectl get pods
```

All pods should show:
- `postgres-...`: Running, 1/1 Ready
- `backend-...`: Running, 1/1 Ready
- `frontend-...`: Running, 1/1 Ready

Check services:
```bash
kubectl get svc
```

Check route:
```bash
kubectl get routes
```

### Step 7: Access the Application

**Method 1: Via Route (Recommended)**
```
http://task-manager.apps-crc.testing
```

**Method 2: Port Forward (if route doesn't work)**
```bash
kubectl port-forward svc/frontend-service 8080:8080
```
Then access: `http://localhost:8080`

### Step 8: Test the Application

1. Open browser and navigate to the application
2. Login with credentials:
   - Username: `admin`
   - Password: `admin123`
3. Add a task by typing in the input field and clicking "Add Task"
4. Verify the task appears in the list
5. Click "Delete" to remove a task
6. Click "Logout" to test session handling

## Troubleshooting Deployment

### Problem: Pods stuck in "Pending"

**Cause**: Often storage-related issues

**Solution**:
```bash
# Check PVC status
kubectl describe pvc postgres-pvc

# Check available storage
kubectl get pv

# Check node affinity
kubectl describe pv postgres-pv
```

If the PV has hardcoded node affinity, update it with your actual node name:
```bash
kubectl get nodes
# Update 01-pv-pvc.yaml with the node name and reapply
```

### Problem: "ImagePullBackOff" error

**Cause**: Images not found locally

**Solution**:
```bash
# Rebuild images
bash ../build.sh localhost:5000

# Verify images exist
docker images | grep app1

# Restart deployment
kubectl rollout restart deployment/frontend
kubectl rollout restart deployment/backend
```

### Problem: Database not initializing

**Cause**: Init script not running or not waiting for database

**Solution**:
```bash
# Check postgres logs
kubectl logs deployment/postgres

# Manually run init script
kubectl exec deployment/postgres -- psql -U postgres < ../database/init.sql

# Verify tables exist
kubectl exec deployment/postgres -- psql -U postgres -d taskdb -c "\dt"
```

### Problem: Backend can't connect to database

**Cause**: Service discovery or credentials issue

**Solution**:
```bash
# Verify service exists
kubectl get svc postgres-service

# Test connectivity from backend pod
kubectl exec deployment/backend -- nslookup postgres-service

# Check environment variables
kubectl exec deployment/backend -- env | grep DB_

# Check database credentials
kubectl get secret db-credentials -o jsonpath='{.data.DB_PASSWORD}' | base64 -d
```

### Problem: Frontend can't reach backend

**Cause**: CORS, service discovery, or network policy

**Solution**:
```bash
# Verify backend service exists
kubectl get svc backend-service

# Test connectivity from frontend pod
kubectl exec deployment/frontend -- nslookup backend-service

# Check backend logs
kubectl logs deployment/backend

# Check for network errors in frontend console (inspect browser)
```

### Problem: Route not working

**Cause**: Route not created or DNS not configured

**Solution**:
```bash
# Verify route exists
kubectl get routes

# Check route configuration
kubectl describe route task-manager-frontend

# Try accessing via port-forward instead
kubectl port-forward svc/frontend-service 8080:8080
```

## Monitoring and Management

### View Application Logs

```bash
# Frontend logs
kubectl logs -f deployment/frontend

# Backend logs (shows all requests)
kubectl logs -f deployment/backend

# Database logs
kubectl logs -f deployment/postgres

# Real-time pod status
kubectl get pods -w

# Watch resources
watch kubectl get pods,svc,routes
```

### Access Database

```bash
# Connect to PostgreSQL
kubectl exec -it deployment/postgres -- psql -U postgres -d taskdb

# Inside psql:
\dt                    # List tables
SELECT * FROM users;   # View users
SELECT * FROM tasks;   # View tasks
SELECT COUNT(*) FROM tasks WHERE user_id = 1;  # Count user's tasks
```

### Backend API Testing

```bash
# Get pod name
POD=$(kubectl get pod -l app=backend -o jsonpath='{.items[0].metadata.name}')

# Test health check
kubectl exec $POD -- curl -s http://localhost:3000/health

# Test readiness check
kubectl exec $POD -- curl -s http://localhost:3000/ready

# Login (returns JWT)
kubectl exec $POD -- curl -X POST http://localhost:3000/api/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"username":"admin","password":"admin123"}'
```

### Check Resource Usage

```bash
# Pod resource usage (requires metrics-server)
kubectl top pods

# Node resource usage
kubectl top nodes

# Detailed pod resource info
kubectl describe pod <pod-name>
```

## Scaling and Updates

### Scale Pods

```bash
# Scale frontend to 3 replicas
kubectl scale deployment frontend --replicas=3

# Scale backend to 2 replicas
kubectl scale deployment backend --replicas=2

# DON'T scale postgres (stateful database)

# Check status
kubectl get pods
```

### Update Image

```bash
# Rebuild updated image
docker build -t localhost:5000/app1-backend:v2.0 ./backend

# Update deployment to use new image
kubectl set image deployment/backend backend=localhost:5000/app1-backend:v2.0

# Watch rollout
kubectl rollout status deployment/backend
```

### Rollback Deployment

```bash
# View rollout history
kubectl rollout history deployment/backend

# Rollback to previous version
kubectl rollout undo deployment/backend

# Rollback to specific revision
kubectl rollout undo deployment/backend --to-revision=1
```

## Cleanup and Removal

### Delete Everything (but keep PV data)

```bash
cd k8s

# Delete in order
kubectl delete -f 08-route.yaml
kubectl delete -f 07-frontend-deployment.yaml
kubectl delete -f 06-backend-deployment.yaml
kubectl delete -f 04-postgres-deployment.yaml
kubectl delete -f 03-services.yaml
kubectl delete -f 05-postgres-init-configmap.yaml
kubectl delete -f 02-configmap-secret.yaml

# Verify resources are gone
kubectl get all
```

### Delete Everything Including Persistent Data

```bash
cd k8s

# Warning: This will delete all data!
kubectl delete -f 01-pv-pvc.yaml
```

### Delete Local Docker Images

```bash
docker rmi localhost:5000/app1-frontend:latest
docker rmi localhost:5000/app1-backend:latest
docker rmi localhost:5000/app1-postgres:latest
```

## Advanced Topics

### Backing Up Database

```bash
# Backup to file
kubectl exec deployment/postgres -- \
  pg_dump -U postgres -d taskdb > backup_$(date +%Y%m%d_%H%M%S).sql

# Restore from file
kubectl cp backup_20240527_120000.sql \
  $(kubectl get pod -l app=postgres -o jsonpath='{.items[0].metadata.name}'):/tmp/backup.sql

kubectl exec deployment/postgres -- \
  psql -U postgres -d taskdb < /tmp/backup.sql
```

### Custom Resource Configuration

Edit manifest files in `k8s/` to customize:

**Change storage size** (`01-pv-pvc.yaml`):
```yaml
storage: 10Gi  # Change from 5Gi to 10Gi
```

**Change resource limits** (`06-backend-deployment.yaml`, `07-frontend-deployment.yaml`):
```yaml
resources:
  requests:
    memory: "256Mi"  # Increase from 128Mi
    cpu: "100m"      # Increase from 50m
```

**Change replicas** (`06-backend-deployment.yaml`):
```yaml
replicas: 3  # Change from 1
```

### Custom Domain/Route

Edit `08-route.yaml`:
```yaml
host: my-custom-domain.apps-crc.testing  # Change hostname
```

## Common Issues and Solutions

| Issue | Cause | Solution |
|-------|-------|----------|
| Pods won't start | PV/storage issue | Check PVC status, verify node affinity |
| Login fails | DB not ready | Wait 30s, check postgres logs |
| Can't reach app | Route not working | Use port-forward, check route config |
| API errors | Backend crashed | Check backend logs, restart pod |
| Data lost | PVC deleted | Make sure to backup before cleanup |

## Performance Optimization

### For Limited Resources (CRC)

Update `k8s/06-backend-deployment.yaml`:
```yaml
replicas: 1  # Keep 1 replica
resources:
  requests:
    memory: "64Mi"   # Reduce from 128Mi
    cpu: "25m"       # Reduce from 50m
```

### For High Load

Update deployments:
```yaml
replicas: 5          # Increase replicas
resources:
  limits:
    memory: "512Mi"  # Increase limit
    cpu: "1000m"     # Increase limit
```

## Security Considerations

⚠️ **This is NOT production-ready!**

For production deployment:

1. **Use Sealed Secrets**
   ```bash
   # Install sealed-secrets operator
   # Encrypt sensitive values
   ```

2. **Enable TLS/HTTPS**
   ```yaml
   # Add TLS to route
   spec:
     tls:
       termination: edge
   ```

3. **Implement RBAC**
   ```bash
   # Create service accounts and roles
   kubectl create serviceaccount app-sa
   ```

4. **Use Private Registry**
   ```bash
   # Push to private container registry
   # Configure imagePullSecrets
   ```

5. **Change Default Credentials**
   - Update admin password
   - Change JWT_SECRET
   - Update database password

## Next Steps

1. **Customize the application**
   - Modify frontend UI in `frontend/index.html`
   - Add features to backend API in `backend/server.js`
   - Adjust database schema in `database/init.sql`

2. **Set up monitoring**
   - Install Prometheus operator
   - Create custom dashboards
   - Set up alerting

3. **Implement CI/CD**
   - Set up GitHub Actions or GitLab CI
   - Automate image builds and pushes
   - Automate deployments

4. **Scale for production**
   - Implement database replication
   - Add load balancing
   - Implement proper backup strategies
   - Set up disaster recovery

## Support and Documentation

- [OpenShift Documentation](https://docs.openshift.com/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Express.js Documentation](https://expressjs.com/)
