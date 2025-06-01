#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}FastAPI X-Ray with OpenTelemetry Deployment Script${NC}"
echo "=================================================="

if ! aws sts get-caller-identity > /dev/null 2>&1; then
    echo -e "${RED}Error: AWS CLI is not configured or credentials are invalid${NC}"
    echo "Please run 'aws configure' or set AWS environment variables"
    exit 1
fi

AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION=$(aws configure get region || echo "ap-northeast-1")

echo -e "${GREEN}AWS Account ID: ${AWS_ACCOUNT_ID}${NC}"
echo -e "${GREEN}AWS Region: ${AWS_REGION}${NC}"

echo -e "${YELLOW}Building and pushing Docker image...${NC}"

aws ecr describe-repositories --repository-names fastapi-xray-demo --region $AWS_REGION > /dev/null 2>&1 || \
aws ecr create-repository --repository-name fastapi-xray-demo --region $AWS_REGION

aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

docker build -f docker/Dockerfile -t fastapi-xray-demo .
docker tag fastapi-xray-demo:latest $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/fastapi-xray-demo:latest

docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/fastapi-xray-demo:latest

echo -e "${GREEN}Docker image pushed successfully${NC}"

echo -e "${YELLOW}Deploying infrastructure with Terraform...${NC}"

cd terraform

terraform init

cat > terraform.tfvars << EOF
aws_region = "$AWS_REGION"
container_image = "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/fastapi-xray-demo:latest"
EOF

terraform plan
echo -e "${YELLOW}Do you want to apply these changes? (y/N)${NC}"
read -r response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    terraform apply -auto-approve
    
    ALB_HOSTNAME=$(terraform output -raw alb_hostname)
    echo -e "${GREEN}Deployment completed successfully!${NC}"
    echo -e "${GREEN}Application URL: http://${ALB_HOSTNAME}${NC}"
    echo -e "${GREEN}Health check: http://${ALB_HOSTNAME}/health${NC}"
    echo -e "${GREEN}API endpoint: http://${ALB_HOSTNAME}/api/users/1${NC}"
    echo ""
    echo -e "${YELLOW}Note: It may take a few minutes for the service to become healthy${NC}"
    echo -e "${YELLOW}Check X-Ray console for traces: https://${AWS_REGION}.console.aws.amazon.com/xray/home${NC}"
else
    echo -e "${YELLOW}Deployment cancelled${NC}"
fi

cd ..
