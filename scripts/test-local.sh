#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Local Testing Script for FastAPI X-Ray Demo${NC}"
echo "============================================="

if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}Error: Docker is not running${NC}"
    exit 1
fi

if [[ -z "$AWS_ACCESS_KEY_ID" || -z "$AWS_SECRET_ACCESS_KEY" ]]; then
    echo -e "${YELLOW}Warning: AWS credentials not found in environment${NC}"
    echo -e "${YELLOW}Traces will not be sent to X-Ray, but local testing will work${NC}"
fi

echo -e "${YELLOW}Starting services with docker-compose...${NC}"

docker compose up -d

echo -e "${YELLOW}Waiting for services to start...${NC}"
sleep 10

echo -e "${GREEN}Testing application endpoints...${NC}"

echo -e "${YELLOW}Testing health endpoint...${NC}"
if curl -s http://localhost:8000/health | grep -q "healthy"; then
    echo -e "${GREEN}✓ Health check passed${NC}"
else
    echo -e "${RED}✗ Health check failed${NC}"
fi

echo -e "${YELLOW}Testing root endpoint...${NC}"
if curl -s http://localhost:8000/ | grep -q "Hello from FastAPI"; then
    echo -e "${GREEN}✓ Root endpoint working${NC}"
else
    echo -e "${RED}✗ Root endpoint failed${NC}"
fi

echo -e "${YELLOW}Testing API endpoint...${NC}"
if curl -s http://localhost:8000/api/users/1 | grep -q "User 1"; then
    echo -e "${GREEN}✓ API endpoint working${NC}"
else
    echo -e "${RED}✗ API endpoint failed${NC}"
fi

echo -e "${YELLOW}Testing external service endpoint...${NC}"
if curl -s http://localhost:8000/api/external | grep -q "success"; then
    echo -e "${GREEN}✓ External service endpoint working${NC}"
else
    echo -e "${RED}✗ External service endpoint failed${NC}"
fi

echo -e "${YELLOW}Testing database simulation endpoint...${NC}"
if curl -s http://localhost:8000/api/database | grep -q "SELECT"; then
    echo -e "${GREEN}✓ Database simulation endpoint working${NC}"
else
    echo -e "${RED}✗ Database simulation endpoint failed${NC}"
fi

echo ""
echo -e "${GREEN}Local testing completed!${NC}"
echo -e "${YELLOW}Application is running at: http://localhost:8000${NC}"
echo -e "${YELLOW}ADOT Collector is running on ports 4317 (gRPC) and 4318 (HTTP)${NC}"
echo ""
echo -e "${YELLOW}To view logs:${NC}"
echo "  docker compose logs fastapi-app"
echo "  docker compose logs adot-collector"
echo ""
echo -e "${YELLOW}To stop services:${NC}"
echo "  docker compose down"
