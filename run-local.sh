#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Starting Task Manager Application with Docker Compose...${NC}"
echo ""
echo -e "${YELLOW}This is for local testing. For OpenShift deployment, see k8s/README.md${NC}"
echo ""

# Check if docker and docker-compose are installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Docker is not installed${NC}"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo -e "${YELLOW}Using 'docker compose' (new format)...${NC}"
    COMPOSE_CMD="docker compose"
else
    COMPOSE_CMD="docker-compose"
fi

# Change to script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Build images
echo -e "${YELLOW}Building images...${NC}"
$COMPOSE_CMD build

# Start services
echo -e "${YELLOW}Starting services...${NC}"
$COMPOSE_CMD up -d

# Wait for services to be healthy
echo -e "${YELLOW}Waiting for services to be ready...${NC}"
sleep 5

# Check status
echo ""
echo -e "${GREEN}✓ Services started!${NC}"
echo ""
echo -e "${YELLOW}Service Status:${NC}"
$COMPOSE_CMD ps
echo ""

echo -e "${YELLOW}Access the application:${NC}"
echo "  Frontend: http://localhost:8080"
echo "  Backend API: http://localhost:3000"
echo "  Database: localhost:5432"
echo ""

echo -e "${YELLOW}Test credentials:${NC}"
echo "  Username: admin"
echo "  Password: admin123"
echo ""

echo -e "${YELLOW}Useful commands:${NC}"
echo "  View logs: $COMPOSE_CMD logs -f [service_name]"
echo "  Stop services: $COMPOSE_CMD down"
echo "  Stop and remove volumes: $COMPOSE_CMD down -v"
echo "  Rebuild: $COMPOSE_CMD build --no-cache"
echo ""

echo -e "${YELLOW}Database access:${NC}"
echo "  docker exec -it app1-postgres psql -U postgres -d taskdb"
echo ""

echo -e "${YELLOW}Backend API test:${NC}"
echo "  curl -X POST http://localhost:3000/api/auth/login \\"
echo "    -H 'Content-Type: application/json' \\"
echo "    -d '{\"username\":\"admin\",\"password\":\"admin123\"}'"
echo ""
