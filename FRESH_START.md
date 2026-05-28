# Fresh Start - Complete Deployment Guide

**Complete instructions to delete CRC and redeploy the entire Task Manager application from scratch.**

## Step 1: Delete Existing CRC Cluster

```bash
# Delete the CRC cluster (this removes all data)
crc delete -f

# Confirm when prompted
```

This will completely clean up the OpenShift cluster.

## Step 2: Start Fresh CRC Cluster

```bash
# Start a new CRC cluster
crc start

# Wait for startup to complete (typically 2-3 minutes)
```

## Step 3: Log in to OpenShift

After CRC starts, use the login credentials provided:

```bash
# Typically:
oc login -u developer -p developer https://api.crc.testing:6443

# Or copy the login command from the CRC start output
```

## Step 4: Deploy the Application

Navigate to the project and run the deployment script:

```bash
cd /home/redhat/Downloads/openshift/app1/k8s
bash deploy.sh
```

**What this does:**
1. Creates the `app1` namespace (isolated from default)
2. Creates ConfigMaps and Secrets with credentials
3. Sets up PersistentVolume and PersistentVolumeClaim for database
4. Deploys PostgreSQL database
5. Deploys Node.js backend API
6. Deploys React frontend
7. Creates Services for internal communication
8. Creates OpenShift Route for external access

**Expected output:**
```
Starting deployment of Task Manager Application...
1. Creating namespace...
2. Applying ConfigMaps and Secrets...
3. Applying PersistentVolume and PersistentVolumeClaim...
3. Deploying PostgreSQL...
PostgreSQL pod has been created
Waiting for PostgreSQL to be ready...
4. Deploying Backend...
Backend pod has been created
Waiting for Backend to be ready...
5. Deploying Frontend...
Frontend pod has been created
Waiting for Frontend to be ready...
6. Creating Route...
✓ Deployment complete!
```

## Step 5: Verify Deployment

```bash
# Check all resources are running
kubectl get all -n app1

# Should show:
# - postgres-xxxxxxxxxxxx-xxxxx  1/1 Running
# - backend-xxxxxxxxxxxx-xxxxx   1/1 Running
# - frontend-xxxxxxxxxxxx-xxxxx  1/1 Running
```

## Step 6: Access the Application

**Frontend URL:**
```
http://task-manager.apps-crc.testing
```

## 🔐 Login Credentials

Use any of these test users:

| Username | Password  |
|----------|-----------|
| admin    | admin123  |
| user1    | admin123  |
| user2    | admin123  |

## 📊 Check Application Status

```bash
# Get all pods
kubectl get pods -n app1

# Get all services
kubectl get svc -n app1

# Get routes
oc get routes -n app1

# View logs
kubectl logs -f deployment/postgres -n app1
kubectl logs -f deployment/backend -n app1
kubectl logs -f deployment/frontend -n app1
```

## 🗄️ Database Information

- **Service Name:** postgres-service.app1.svc.cluster.local
- **Port:** 5432
- **Database:** taskdb
- **Database User:** postgres
- **Database Password:** password

## 🚀 Deployment Summary

The deployment creates these resources in the `app1` namespace:

**Deployments:**
- postgres (1 replica, 256Mi-512Mi RAM)
- backend (1 replica, 256Mi-512Mi RAM)
- frontend (1 replica, 128Mi-256Mi RAM)

**Persistent Storage:**
- postgres-pvc (5Gi, dynamically provisioned)

**Services:**
- postgres-service (internal, port 5432)
- backend-service (internal, port 3000)
- frontend-service (internal, port 8080)

**Routes:**
- task-manager (external HTTP access)

## 🧹 Cleanup

To remove everything and start over:

```bash
# Delete the app1 namespace (removes all resources)
kubectl delete namespace app1

# Or delete individual manifests
cd k8s
kubectl delete -f 08-route.yaml -n app1
kubectl delete -f 07-frontend-deployment.yaml -n app1
kubectl delete -f 06-backend-deployment.yaml -n app1
kubectl delete -f 04-postgres-deployment.yaml -n app1
kubectl delete -f 03-services.yaml -n app1
kubectl delete -f 01-pv-pvc.yaml -n app1
kubectl delete -f 02-configmap-secret.yaml -n app1
kubectl delete -f 00-namespace.yaml
```

## 📋 One-Command Complete Reset

```bash
# Delete CRC cluster and redeploy everything fresh
crc delete -f && crc start && \
sleep 30 && \
oc login -u developer -p developer https://api.crc.testing:6443 && \
cd /home/redhat/Downloads/openshift/app1/k8s && \
bash deploy.sh
```

## ⚠️ Common Issues

**Pod stuck in Pending state:**
```bash
# Check why it's pending
kubectl describe pod <pod-name> -n app1

# If memory issue, reduce resource limits in deployment YAML
```

**Database not ready:**
```bash
# Check postgres logs
kubectl logs -f deployment/postgres -n app1

# Restart if stuck
kubectl rollout restart deployment/postgres -n app1
```

**Cannot access frontend URL:**
```bash
# Verify route exists
oc get routes -n app1

# Check frontend pod logs
kubectl logs -f deployment/frontend -n app1
```

## 🔗 Additional Resources

- k8s/README.md - Kubernetes specific documentation
- backend/ - Backend API source code
- frontend/ - Frontend application source code
- database/ - Database initialization scripts
