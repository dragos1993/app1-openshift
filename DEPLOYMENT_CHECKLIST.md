# Deployment Checklist & Verification

Use this checklist to verify your deployment is ready and working correctly.

## Pre-Deployment Checklist

### Environment Setup
- [ ] OpenShift CRC is running: `crc status`
- [ ] OpenShift environment loaded: `eval $(crc oc-env)`
- [ ] kubectl/oc CLI is available: `kubectl version`
- [ ] Docker is installed: `docker --version`
- [ ] Cluster access verified: `kubectl auth can-i create deployments`
- [ ] Storage class exists: `kubectl get sc` (shows `crc-csi-hostpath-provisioner`)

### Project Files
- [ ] All source files created in `/home/redhat/Downloads/openshift/app1`
- [ ] Frontend files exist: `frontend/index.html`, `frontend/Dockerfile`
- [ ] Backend files exist: `backend/server.js`, `backend/package.json`, `backend/Dockerfile`
- [ ] Database files exist: `database/init.sql`, `database/Dockerfile`
- [ ] K8s manifests exist: `k8s/*.yaml`
- [ ] Scripts are executable: `build.sh`, `run-local.sh`, `k8s/deploy.sh`

### Documentation
- [ ] README.md reviewed
- [ ] DEPLOYMENT_GUIDE.md available
- [ ] QUICK_REFERENCE.md available
- [ ] PROJECT_STRUCTURE.md available

## Build Verification

### Docker Images
```bash
# Run from app1 directory
bash build.sh localhost:5000
```

- [ ] Build completes without errors
- [ ] Images created: `docker images | grep app1`
- [ ] All 3 images present:
  - [ ] app1-frontend:latest
  - [ ] app1-backend:latest
  - [ ] app1-postgres:latest

## Deployment Verification

### Deploy to OpenShift
```bash
cd k8s
bash deploy.sh
```

- [ ] ConfigMaps created: `kubectl get configmap`
- [ ] Secrets created: `kubectl get secrets`
- [ ] PV/PVC created: `kubectl get pv,pvc`
- [ ] Services created: `kubectl get svc`
- [ ] Deployments created: `kubectl get deployment`
- [ ] Pods starting: `kubectl get pods`

### Wait for Readiness
```bash
kubectl get pods -w
```

Wait for all pods to show "Running" and "1/1" Ready:
- [ ] postgres-xxxxx: Running, 1/1 Ready ✓
- [ ] backend-xxxxx: Running, 1/1 Ready ✓
- [ ] frontend-xxxxx: Running, 1/1 Ready ✓

Expected time: 2-3 minutes

## Pod Health Verification

### Check Pod Logs
```bash
# Check for errors
kubectl logs deployment/postgres | grep -i error
kubectl logs deployment/backend | grep -i error
kubectl logs deployment/frontend | grep -i error
```

- [ ] PostgreSQL logs show no errors
- [ ] Backend logs show "listening" or "running"
- [ ] Frontend logs show server started

### Verify Probes Are Working
```bash
kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.conditions[*].type}{"\n"}{end}'
```

- [ ] All pods have "Ready" condition
- [ ] All pods have "ContainersReady" condition
- [ ] No pods in "NotReady" state

## Application Verification

### Access the Application
```bash
# Check route
kubectl get routes

# OR port-forward if route doesn't work
kubectl port-forward svc/frontend-service 8080:8080
```

- [ ] Route created: `task-manager.apps-crc.testing`
- [ ] Route is accessible: `curl http://task-manager.apps-crc.testing`
- [ ] Frontend loads in browser
- [ ] Login page displays

### Test Login
- [ ] Navigate to `http://task-manager.apps-crc.testing`
- [ ] Username field appears
- [ ] Password field appears
- [ ] Login button appears

### Test Credentials
```
Username: admin
Password: admin123
```

- [ ] Login succeeds
- [ ] User info shows: "Logged in as: admin"
- [ ] Dashboard displays
- [ ] Task input field appears

### Test Task Management
- [ ] Type task name: "Test task 1"
- [ ] Click "Add Task"
- [ ] Task appears in list
- [ ] Timestamp shows for task
- [ ] Delete button works
- [ ] Task is removed from list

### Test Session Management
- [ ] Click "Logout"
- [ ] Redirected to login page
- [ ] Login page displays again
- [ ] Previous login info cleared

## Database Verification

### Connect to Database
```bash
kubectl exec -it deployment/postgres -- \
  psql -U postgres -d taskdb
```

- [ ] psql prompt appears
- [ ] No errors during connection

### Verify Schema
```sql
\dt
```

- [ ] users table exists
- [ ] tasks table exists

### Check Data
```sql
SELECT * FROM users;
```

- [ ] admin user exists
- [ ] user1 exists
- [ ] user2 exists
- [ ] Passwords are hashed (bcrypt format)

```sql
SELECT COUNT(*) FROM tasks WHERE user_id = 1;
```

- [ ] Admin's tasks are counted correctly
- [ ] Each user's tasks are isolated

## API Verification

### Test API Endpoints
```bash
# Test login endpoint
curl -X POST http://localhost:3000/api/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"username":"admin","password":"admin123"}'
```

- [ ] Response is valid JSON
- [ ] Contains auth token
- [ ] No errors

### Get Current User
```bash
# Extract token from login response and use it
curl -H "Authorization: Bearer TOKEN" \
  http://localhost:3000/api/auth/me
```

- [ ] Returns current user info
- [ ] Shows username: admin

### Get Tasks
```bash
curl http://localhost:3000/api/tasks
```

- [ ] Returns JSON array
- [ ] Shows user's tasks
- [ ] Contains task names

## Performance Verification

### Check Resource Usage
```bash
kubectl top pods
```

- [ ] Frontend using < 100Mi memory ✓
- [ ] Backend using < 200Mi memory ✓
- [ ] PostgreSQL using < 300Mi memory ✓

### Check Pod Restart Count
```bash
kubectl get pods
```

- [ ] All RESTARTS column shows 0
- [ ] No pod is continuously restarting

## Storage Verification

### Verify Persistent Storage
```bash
kubectl get pv,pvc
```

- [ ] PV exists: postgres-pv
- [ ] PVC exists: postgres-pvc
- [ ] PVC status: Bound
- [ ] Storage size: 5Gi

### Test Data Persistence
```bash
# Add a task and note the ID
# Then delete the backend pod to trigger restart

kubectl delete pod deployment/postgres-xxxxx  # Note: This is for postgres pod

# Wait for pod to restart
kubectl get pods -w

# Verify data still exists
kubectl exec deployment/postgres -- \
  psql -U postgres -d taskdb -c "SELECT COUNT(*) FROM tasks;"
```

- [ ] Pod restarts
- [ ] Data is still present
- [ ] Count matches before restart

## Cleanup Test

### Test Partial Cleanup
```bash
# Delete pods (should auto-restart)
kubectl delete pod deployment/frontend-xxxxx

# Watch pods restart
kubectl get pods -w
```

- [ ] Pod is recreated automatically
- [ ] Application remains accessible
- [ ] Data is preserved

## Documentation Verification

- [ ] README.md is clear and complete
- [ ] DEPLOYMENT_GUIDE.md has all steps
- [ ] QUICK_REFERENCE.md works as expected
- [ ] PROJECT_STRUCTURE.md explains architecture
- [ ] k8s/README.md covers K8s details

## Final Checklist

### All Components Working
- [ ] Frontend pod running and healthy
- [ ] Backend API running and responding
- [ ] PostgreSQL database running and responding
- [ ] Services discoverable
- [ ] Route accessible
- [ ] Storage persistent
- [ ] Probes working correctly

### All Features Working
- [ ] User authentication working
- [ ] Task creation working
- [ ] Task deletion working
- [ ] Task listing working
- [ ] Logout working
- [ ] Session management working

### All Documentation Complete
- [ ] User can deploy from scratch
- [ ] User can troubleshoot issues
- [ ] User can customize components
- [ ] User can monitor system
- [ ] User can scale pods

## Common Issues & Quick Fixes

| Issue | Quick Fix | Mark |
|-------|-----------|------|
| Pods won't start | `kubectl describe pod <name>` | [ ] |
| Can't connect to DB | `kubectl logs postgres` | [ ] |
| API not responding | Check backend logs | [ ] |
| Frontend blank | Check browser console | [ ] |
| Route not working | Use port-forward instead | [ ] |
| Storage issues | Check PVC status | [ ] |

## Performance Targets

- [ ] Pod startup: < 2 minutes
- [ ] Login response: < 1 second
- [ ] Task creation: < 1 second
- [ ] Task listing: < 500ms
- [ ] Memory usage: < 600Mi total
- [ ] CPU usage: < 500m total

## Sign-Off

- [ ] All pre-deployment checks passed
- [ ] Build completed successfully
- [ ] Deployment completed successfully
- [ ] All pods healthy
- [ ] Application fully functional
- [ ] User can access application
- [ ] All features working
- [ ] Documentation complete

**Deployment Date**: _______________  
**Verified By**: _______________  
**Status**: ✅ READY FOR USE

## Notes
```
[Use this space for any notes or issues encountered]

```
