# Project Structure Overview

```
/home/redhat/Downloads/openshift/app1/
│
├── README.md                          # Main project documentation
├── DEPLOYMENT_GUIDE.md               # Complete deployment instructions
├── .env.example                      # Environment variables reference
├── docker-compose.yml                # Local testing with Docker Compose
├── build.sh                          # Build Docker images script
├── run-local.sh                      # Run locally with Docker Compose
│
├── frontend/                         # Frontend Web Application
│   ├── index.html                   # Single-page HTML/JavaScript app
│   │   - Login page with form
│   │   - Task management dashboard
│   │   - User session handling
│   └── Dockerfile                   # Frontend container image
│       - Node.js 18 Alpine base
│       - HTTP server for static content
│
├── backend/                          # Backend REST API
│   ├── server.js                    # Express.js API server
│   │   - User authentication routes
│   │   - Task CRUD endpoints
│   │   - Health/readiness checks
│   │   - JWT token management
│   ├── package.json                 # Node.js dependencies
│   │   - express, pg, bcryptjs
│   │   - jsonwebtoken, cors
│   └── Dockerfile                   # Backend container image
│       - Node.js 18 Alpine base
│       - Production dependencies
│
├── database/                         # PostgreSQL Database
│   ├── init.sql                     # Database initialization script
│   │   - Create users table
│   │   - Create tasks table
│   │   - Create indexes
│   │   - Insert sample users
│   ├── init.sh                      # Database init helper (unused)
│   └── Dockerfile                   # PostgreSQL container image
│       - PostgreSQL 15 Alpine base
│       - Health checks
│
└── k8s/                              # Kubernetes/OpenShift Manifests
    ├── README.md                     # K8s-specific documentation
    │
    ├── 01-pv-pvc.yaml               # Storage configuration
    │   - PersistentVolume (5Gi)
    │   - PersistentVolumeClaim
    │   - Storage class: crc-csi-hostpath-provisioner
    │
    ├── 02-configmap-secret.yaml     # Configuration & Secrets
    │   - ConfigMap: db-config (DB connection parameters)
    │   - ConfigMap: admin-user-config (admin username)
    │   - Secret: db-credentials (password, JWT secret)
    │
    ├── 03-services.yaml              # Service Discovery
    │   - postgres-service (port 5432)
    │   - backend-service (port 3000)
    │   - frontend-service (port 8080)
    │
    ├── 04-postgres-deployment.yaml   # PostgreSQL Pod
    │   - 1 replica
    │   - Liveness probe: pg_isready every 10s
    │   - Readiness probe: pg_isready -d taskdb every 5s
    │   - Volume: PVC mounted at /var/lib/postgresql/data
    │   - Resources: 256Mi/512Mi memory, 100m/500m CPU
    │
    ├── 05-postgres-init-configmap.yaml  # DB Init ConfigMap
    │   - Contains init.sql script
    │   - Tables, indexes, sample data
    │
    ├── 06-backend-deployment.yaml    # Backend API Pod
    │   - 1 replica
    │   - Liveness probe: HTTP GET /health every 10s
    │   - Readiness probe: HTTP GET /ready every 5s
    │   - Environment: DB credentials from ConfigMap/Secret
    │   - Resources: 128Mi/256Mi memory, 50m/300m CPU
    │
    ├── 07-frontend-deployment.yaml   # Frontend Pod
    │   - 1 replica
    │   - Liveness probe: HTTP GET / every 10s
    │   - Readiness probe: HTTP GET / every 5s
    │   - Resources: 64Mi/128Mi memory, 25m/200m CPU
    │
    ├── 08-route.yaml                 # OpenShift Route
    │   - External access: http://task-manager.apps-crc.testing
    │   - Routes to frontend-service
    │
    ├── deploy.sh                     # Automated deployment script
    │   - Applies manifests in order
    │   - Waits for pods to be ready
    │   - Provides helpful output
    │
    └── cleanup.sh (optional)         # Cleanup script
        - Deletes all resources
```

## Component Descriptions

### Frontend Container
- **Image**: `localhost:5000/app1-frontend:latest`
- **Port**: 8080
- **Technology**: HTML5, Vanilla JavaScript
- **Purpose**: User-facing web application
- **Features**:
  - Login page with username/password form
  - Task management dashboard
  - Real-time task list refresh
  - Logout functionality

### Backend Container
- **Image**: `localhost:5000/app1-backend:latest`
- **Port**: 3000
- **Technology**: Node.js, Express.js, PostgreSQL driver
- **Purpose**: REST API for authentication and task management
- **Endpoints**:
  - `POST /api/auth/login` - User authentication
  - `GET /api/auth/me` - Get current user
  - `POST /api/auth/logout` - Logout
  - `GET /api/tasks` - List user's tasks
  - `POST /api/tasks` - Create new task
  - `DELETE /api/tasks/:id` - Delete task
  - `GET /health` - Health check
  - `GET /ready` - Readiness check

### PostgreSQL Container
- **Image**: `localhost:5000/app1-postgres:latest` (or `postgres:15-alpine`)
- **Port**: 5432
- **Technology**: PostgreSQL 15
- **Purpose**: Persistent data storage
- **Tables**:
  - `users`: username, password_hash, created_at
  - `tasks`: user_id, name, created_at
- **Sample Users**:
  - admin / admin123
  - user1 / admin123
  - user2 / admin123

## Data Flow

```
User Browser
    ↓
Frontend (Port 8080)
    ↓ (API calls via fetch)
Backend Service (Port 3000)
    ↓ (SQL queries)
PostgreSQL Service (Port 5432)
    ↓
Persistent Volume (5Gi storage)
```

## Authentication Flow

```
1. User submits login form
   ↓
2. Frontend POST /api/auth/login with credentials
   ↓
3. Backend validates credentials against DB
   ↓
4. Backend generates JWT token
   ↓
5. Token returned in HTTP-only cookie
   ↓
6. Subsequent requests include token in cookie
   ↓
7. Backend verifies token for protected routes
```

## Deployment Architecture

```
OpenShift Node (CRC)
├── Pod: frontend-xxxxx
│   ├── Container: frontend
│   ├── Port: 8080
│   └── PVC: None
├── Pod: backend-xxxxx
│   ├── Container: backend
│   ├── Port: 3000
│   └── PVC: None
└── Pod: postgres-xxxxx
    ├── Container: postgres
    ├── Port: 5432
    └── PVC: postgres-pvc → PV: postgres-pv → /var/task-manager-data

Services:
├── frontend-service → frontend pod:8080
├── backend-service → backend pod:3000
└── postgres-service → postgres pod:5432

Route:
└── task-manager-frontend → frontend-service:8080
    Accessible at: http://task-manager.apps-crc.testing
```

## Configuration Sources

### Environment Variables (set from ConfigMap/Secret)

**Backend receives**:
- `DB_USER`: postgres
- `DB_PASSWORD`: [from Secret]
- `DB_NAME`: taskdb
- `DB_HOST`: postgres-service
- `DB_PORT`: 5432
- `JWT_SECRET`: [from Secret]
- `PORT`: 3000

### ConfigMaps

**db-config**: Database connection parameters
```
DB_USER=postgres
DB_NAME=taskdb
DB_HOST=postgres-service
DB_PORT=5432
```

**admin-user-config**: Admin user configuration
```
ADMIN_USER=admin
```

**postgres-init-script**: SQL initialization script
```
(Contains full init.sql content)
```

### Secrets

**db-credentials**: Sensitive credentials
```
DB_PASSWORD=password
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production
```

## Probe Configuration

### Readiness Probes
- Indicates pod is ready to serve traffic
- Used by load balancers/services
- Failure removes pod from endpoints

### Liveness Probes
- Indicates pod is still alive
- Failure triggers container restart
- Prevents zombie pods

| Pod | Readiness | Liveness | Function |
|-----|-----------|----------|----------|
| Frontend | HTTP GET / | HTTP GET / | Check if server responding |
| Backend | HTTP GET /ready | HTTP GET /health | Check DB connectivity & server |
| Postgres | pg_isready -d taskdb | pg_isready | Check database process |

## Resource Allocation

### Memory Requests (guaranteed)
- Frontend: 64Mi
- Backend: 128Mi
- Postgres: 256Mi
- **Total**: ~450Mi

### Memory Limits (maximum)
- Frontend: 128Mi
- Backend: 256Mi
- Postgres: 512Mi
- **Total**: ~900Mi

### CPU Requests (guaranteed)
- Frontend: 25m
- Backend: 50m
- Postgres: 100m
- **Total**: ~175m

### CPU Limits (maximum)
- Frontend: 200m
- Backend: 300m
- Postgres: 500m
- **Total**: ~1000m (1 CPU core)

## Security Configuration

⚠️ **Development Configuration** - Not suitable for production

### Credentials
- Hardcoded in manifests (ConfigMap/Secret)
- Visible in base64 encoding
- Default/weak passwords

### Network
- No network policies
- No TLS encryption
- No authentication between services

### Data
- Single replica (no redundancy)
- PV with local storage (no distributed backup)
- No data encryption at rest

## File Dependencies

- `frontend/index.html`: Makes API calls to `/api/*` endpoints
- `backend/server.js`: Requires PostgreSQL database to be running
- `database/init.sql`: Creates schema, required before backend starts
- All manifests: Reference ConfigMaps, Secrets, Services by name

## Deployment Order Importance

1. **ConfigMaps & Secrets first**: Deployments reference these
2. **Storage second**: PostgreSQL deployment needs PVC
3. **PostgreSQL third**: Database must be ready before backend
4. **Backend fourth**: Depends on database, serves API
5. **Frontend fifth**: Depends on backend API
6. **Route last**: Exposing frontend to external traffic

## Scaling Considerations

- **Frontend**: Can scale to multiple replicas (stateless)
- **Backend**: Can scale to multiple replicas (stateless, shared DB)
- **PostgreSQL**: Should NOT be scaled (single instance, stateful)

For multi-replica PostgreSQL setup, requires additional configuration:
- PostgreSQL streaming replication
- Kubernetes StatefulSet instead of Deployment
- Persistent shared storage or WAL archiving

## Backup & Recovery

### Automatic
- PVC backed by PV with persistent storage
- Data survives pod restart

### Manual
```bash
# Backup
kubectl exec postgres-pod -- pg_dump -U postgres -d taskdb > backup.sql

# Restore
kubectl exec postgres-pod -- psql -U postgres -d taskdb < backup.sql
```

### Disaster Recovery
- Delete PVC/PV to start fresh
- Re-run database init script
- Data loss if PV deleted

## Monitoring Points

**Health checks to monitor**:
- HTTP 200 from `/health` endpoint
- HTTP 200 from `/ready` endpoint
- `pg_isready` success for database
- Pod restart count
- CPU/memory usage

**Logs to check**:
- Backend logs: API errors, database connection issues
- Postgres logs: Query errors, init script issues
- Frontend logs: API call failures, JavaScript errors

**Metrics to track**:
- Response times
- Error rates
- Database query performance
- Pod resource usage
- Pod restart count
