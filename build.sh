#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

set -e

echo -e "${YELLOW}Building Docker images for Task Manager Application...${NC}"

REGISTRY="${1:-docker.io/dragos93}"
echo "Using registry: $REGISTRY"

# Change to project root
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$SCRIPT_DIR/.."

echo -e "${YELLOW}1. Building Frontend image...${NC}"
docker build -t $REGISTRY/app1-frontend:latest "$PROJECT_ROOT/frontend"

echo -e "${GREEN}✓ Frontend image built: $REGISTRY/app1-frontend:latest${NC}"

echo -e "${YELLOW}2. Building Backend image...${NC}"
docker build -t $REGISTRY/app1-backend:latest "$PROJECT_ROOT/backend"

echo -e "${GREEN}✓ Backend image built: $REGISTRY/app1-backend:latest${NC}"

echo -e "${YELLOW}3. Building Database image...${NC}"
docker build -t $REGISTRY/app1-postgres:latest "$PROJECT_ROOT/database"

echo -e "${GREEN}✓ Database image built: $REGISTRY/app1-postgres:latest${NC}"

echo -e "${GREEN}✓ All images built successfully!${NC}"
echo ""
echo -e "${YELLOW}To push images to registry:${NC}"
echo "  docker push $REGISTRY/app1-frontend:latest"
echo "  docker push $REGISTRY/app1-backend:latest"
echo "  docker push $REGISTRY/app1-postgres:latest"
echo ""
echo -e "${YELLOW}To deploy to OpenShift/Kubernetes:${NC}"
echo "  cd k8s"
echo "  bash deploy.sh"
