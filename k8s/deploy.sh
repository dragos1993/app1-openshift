#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

set -e

echo -e "${YELLOW}Starting deployment of Task Manager Application...${NC}"

# Function to check if pod is ready
check_pod_ready() {
    local pod_name=$1
    local namespace=${2:-default}
    
    echo "Waiting for $pod_name to be ready..."
    kubectl wait --for=condition=ready pod \
        -l app=$pod_name \
        -n $namespace \
        --timeout=300s || return 1
}

# Change to script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Apply manifests
echo -e "${YELLOW}1. Applying ConfigMaps and Secrets...${NC}"
kubectl apply -f 02-configmap-secret.yaml
kubectl apply -f 05-postgres-init-configmap.yaml

echo -e "${YELLOW}2. Applying PersistentVolume and PersistentVolumeClaim...${NC}"
kubectl apply -f 01-pv-pvc.yaml

echo -e "${YELLOW}3. Deploying PostgreSQL...${NC}"
kubectl apply -f 04-postgres-deployment.yaml
kubectl apply -f 03-services.yaml

echo -e "${GREEN}PostgreSQL pod has been created${NC}"
echo "Waiting for PostgreSQL to be ready..."
check_pod_ready postgres || echo -e "${RED}PostgreSQL pod failed to become ready${NC}"

# Wait a bit for database to initialize
echo "Waiting for database initialization..."
sleep 10

echo -e "${YELLOW}4. Deploying Backend...${NC}"
kubectl apply -f 06-backend-deployment.yaml

echo -e "${GREEN}Backend pod has been created${NC}"
echo "Waiting for Backend to be ready..."
check_pod_ready backend || echo -e "${RED}Backend pod failed to become ready${NC}"

echo -e "${YELLOW}5. Deploying Frontend...${NC}"
kubectl apply -f 07-frontend-deployment.yaml

echo -e "${GREEN}Frontend pod has been created${NC}"
echo "Waiting for Frontend to be ready..."
check_pod_ready frontend || echo -e "${RED}Frontend pod failed to become ready${NC}"

echo -e "${YELLOW}6. Creating Route...${NC}"
kubectl apply -f 08-route.yaml

echo -e "${GREEN}✓ Deployment complete!${NC}"
echo ""
echo -e "${YELLOW}Services created:${NC}"
echo "  - postgres-service (internal, port 5432)"
echo "  - backend-service (internal, port 3000)"
echo "  - frontend-service (internal, port 8080)"
echo ""
echo -e "${YELLOW}Check pod status:${NC}"
echo "  kubectl get pods"
echo ""
echo -e "${YELLOW}Check services:${NC}"
echo "  kubectl get svc"
echo ""
echo -e "${YELLOW}Check route:${NC}"
echo "  kubectl get routes"
echo ""
echo -e "${YELLOW}View application:${NC}"
echo "  http://task-manager.apps-crc.testing"
echo ""
echo -e "${YELLOW}Test credentials:${NC}"
echo "  Username: admin"
echo "  Password: admin123"
echo "  (or user1/user2 with same password)"
echo ""
echo -e "${YELLOW}To view logs:${NC}"
echo "  kubectl logs -f deployment/frontend"
echo "  kubectl logs -f deployment/backend"
echo "  kubectl logs -f deployment/postgres"
echo ""
echo -e "${YELLOW}To delete all resources:${NC}"
echo "  kubectl delete -f 08-route.yaml"
echo "  kubectl delete -f 07-frontend-deployment.yaml"
echo "  kubectl delete -f 06-backend-deployment.yaml"
echo "  kubectl delete -f 04-postgres-deployment.yaml"
echo "  kubectl delete -f 03-services.yaml"
echo "  kubectl delete -f 05-postgres-init-configmap.yaml"
echo "  kubectl delete -f 02-configmap-secret.yaml"
echo "  kubectl delete -f 01-pv-pvc.yaml"
