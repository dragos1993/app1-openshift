# Task Manager Application for OpenShift

A complete web application with frontend, backend, and PostgreSQL database, deployable on OpenShift/Kubernetes with CRC.

## Features

✅ **User Authentication**
- Login with username and password stored in PostgreSQL
- JWT token-based authentication
- Secure password hashing with bcrypt

✅ **Task Management**
- Create, view, and delete tasks
- Tasks stored separately from user table
- Per-user task isolation

✅ **Three Separate Pods**
- **Frontend**: HTML/JavaScript UI (port 8080)
- **Backend**: Node.js Express API (port 3000)
- **Database**: PostgreSQL 15 (port 5432)

✅ **Kubernetes Features**
- Readiness probes for all pods
- Liveness probes for all pods
- ConfigMap for admin user configuration
- Secrets for database password and JWT secret
- PersistentVolume and PersistentVolumeClaim for database storage
- Service discovery between pods
- OpenShift Route for external access

## Project Structure

```
app1/
├── frontend/
│   ├── index.html          # Web UI (login + task management)
│   └── Dockerfile
├── backend/
│   ├── package.json
│   ├── server.js           # Express API server
│   └── Dockerfile
├── database/
│   ├── init.sql            # Database schema and initial data
│   ├── Dockerfile
│   └── init.sh
├── k8s/
│   ├── 01-pv-pvc.yaml                    # Storage configuration
│   ├── 02-configmap-secret.yaml          # ConfigMap and Secrets
│   ├── 03-services.yaml                  # Kubernetes Services
│   ├── 04-postgres-deployment.yaml       # PostgreSQL Pod
│   ├── 05-postgres-init-configmap.yaml   # Database init scripts
│   ├── 06-backend-deployment.yaml        # Backend Pod
│   ├── 07-frontend-deployment.yaml       # Frontend Pod
│   ├── 08-route.yaml                     # OpenShift Route
│   ├── deploy.sh                         # Deployment script
│   └── README.md                         # K8s specific docs
├── build.sh                # Docker image build script
└── README.md              # This file
```

## Prerequisites

- OpenShift Container Runtime (CRC) running
- `kubectl` or `oc` CLI tools
- Docker (for building images)
- Storage class: `crc-csi-hostpath-provisioner` (should be default in CRC)

## Quick Start

### 1. Build Docker Images

```bash
cd /home/redhat/Downloads/openshift/app1
bash build.sh [registry_url]
```

If using CRC's internal registry:
```bash
bash build.sh localhost:5000
```

### 2. Deploy to OpenShift

```bash
cd k8s
bash deploy.sh
```

This will:
- Create ConfigMaps and Secrets
- Create PersistentVolume and PersistentVolumeClaim
- Deploy PostgreSQL pod
- Deploy Backend API pod
- Deploy Frontend pod
- Create Services for internal communication
- Create Route for external access

### 3. Access the Application

```
http://task-manager.apps-crc.testing
```

## Test Credentials

Three test users are pre-populated in the database:

| Username | Password |
|----------|----------|
| admin    | admin123 |
| user1    | admin123 |
| user2    | admin123 |

## API Endpoints

### Authentication
- `POST /api/auth/login` - Login (returns JWT in cookie)
- `GET /api/auth/me` - Get current user info
- `POST /api/auth/logout` - Logout

### Tasks
- `GET /api/tasks` - Get all tasks for current user
- `POST /api/tasks` - Create new task
- `DELETE /api/tasks/:id` - Delete a task

### Health Checks
- `GET /health` - Backend health check
- `GET /ready` - Backend readiness check

## Configuration

### Environment Variables (in Kubernetes)

**Database Configuration** (ConfigMap: `db-config`):
- `DB_USER`: PostgreSQL username
- `DB_NAME`: Database name
- `DB_HOST`: Database service hostname
- `DB_PORT`: Database port

**Secrets** (Secret: `db-credentials`):
- `DB_PASSWORD`: PostgreSQL password
- `JWT_SECRET`: Secret key for JWT tokens

**Admin User** (ConfigMap: `admin-user-config`):
- `ADMIN_USER`: Admin username

### Storage

- **Storage Class**: `crc-csi-hostpath-provisioner`
- **Storage Size**: 5Gi
- **Mount Path**: `/var/lib/postgresql/data` (in postgres pod)

## Probes Configuration

### Liveness Probes
- **Postgres**: `pg_isready` command every 10s, fails after 3 retries
- **Backend**: HTTP GET `/health` every 10s, fails after 3 retries
- **Frontend**: HTTP GET `/` every 10s, fails after 3 retries

### Readiness Probes
- **Postgres**: `pg_isready -d taskdb` every 5s, fails after 3 retries
- **Backend**: HTTP GET `/ready` every 5s, fails after 2 retries
- **Frontend**: HTTP GET `/` every 5s, fails after 2 retries

## Useful Commands

### Check Status
```bash
# View all pods
kubectl get pods

# View services
kubectl get svc

# View routes
kubectl get routes

# View persistent volumes
kubectl get pv,pvc
```

### View Logs
```bash
# Frontend logs
kubectl logs -f deployment/frontend

# Backend logs
kubectl logs -f deployment/backend

# Database logs
kubectl logs -f deployment/postgres
```

### Port Forward (Local Testing)
```bash
# Access backend directly
kubectl port-forward svc/backend-service 3000:3000

# Access database directly
kubectl port-forward svc/postgres-service 5432:5432
```

### Database Access
```bash
# Connect to database pod
kubectl exec -it deployment/postgres -- psql -U postgres -d taskdb

# View users table
SELECT * FROM users;

# View tasks table
SELECT * FROM tasks;
```

### Delete Deployment
```bash
cd k8s
bash deploy.sh delete
```

Or manually:
```bash
kubectl delete deployment frontend backend postgres
kubectl delete service frontend-service backend-service postgres-service
kubectl delete route task-manager-frontend
kubectl delete secret db-credentials
kubectl delete configmap db-config admin-user-config postgres-init-script
kubectl delete pvc postgres-pvc
kubectl delete pv postgres-pv
```

## Troubleshooting

### Pods not starting?
```bash
# Check pod status
kubectl describe pod <pod-name>

# Check logs
kubectl logs <pod-name>
```

### Database not ready?
```bash
# Check database logs
kubectl logs -f deployment/postgres

# Connect and check tables
kubectl exec -it deployment/postgres -- psql -U postgres -d taskdb -c "\dt"
```

### Backend can't connect to database?
```bash
# Check if postgres service is reachable from backend pod
kubectl exec -it deployment/backend -- curl http://postgres-service:5432

# Check backend environment variables
kubectl exec -it deployment/backend -- env | grep DB_
```

### Frontend can't reach backend?
```bash
# Check service discovery
kubectl exec -it deployment/frontend -- nslookup backend-service

# Check backend service
kubectl get svc backend-service
```

## Security Notes

⚠️ **Not for Production Use**

This application contains hardcoded credentials and is designed for testing/learning:
- Passwords are visible in manifests
- JWT secret is insecure
- No TLS/HTTPS
- No RBAC policies

For production:
1. Use sealed-secrets or external secret management
2. Generate strong JWT secrets
3. Enable HTTPS/TLS
4. Implement proper RBAC
5. Use private container registry
6. Implement rate limiting and input validation

## Database Schema

### Users Table
```sql
CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  username VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### Tasks Table
```sql
CREATE TABLE tasks (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name VARCHAR(500) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

## License

This is a demonstration application for learning OpenShift/Kubernetes.
