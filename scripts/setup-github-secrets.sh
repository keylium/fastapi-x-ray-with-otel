#!/bin/bash


set -e

PROJECT_NAME="fastapi-xray-otel"
REPO="keylium/fastapi-x-ray-with-otel"

echo "GitHub Secrets Setup for FastAPI X-Ray Demo"
echo "==========================================="

if ! command -v gh &> /dev/null; then
    echo "Error: GitHub CLI (gh) is not installed"
    echo "Please install it from: https://cli.github.com/"
    exit 1
fi

if ! gh auth status &> /dev/null; then
    echo "Error: Not authenticated with GitHub CLI"
    echo "Please run: gh auth login"
    exit 1
fi

echo "✅ GitHub CLI is installed and authenticated"

echo "Getting GitHub Actions IAM role ARN from Terraform..."

if [ ! -f "terraform/terraform.tfstate" ]; then
    echo "Error: Terraform state file not found"
    echo "Please run 'terraform apply' first to create the IAM role"
    exit 1
fi

cd terraform

ROLE_ARN=$(terraform output -raw github_actions_role_arn 2>/dev/null || echo "")

if [ -z "$ROLE_ARN" ]; then
    echo "Error: Could not get GitHub Actions role ARN from Terraform output"
    echo "Please ensure Terraform has been applied and the role exists"
    exit 1
fi

echo "✅ Found GitHub Actions IAM role: $ROLE_ARN"

cd ..

echo "Setting AWS_ROLE_TO_ASSUME secret in GitHub repository..."

gh secret set AWS_ROLE_TO_ASSUME --body "$ROLE_ARN" --repo "$REPO"

if [ $? -eq 0 ]; then
    echo "✅ Successfully set AWS_ROLE_TO_ASSUME secret"
    echo "Secret value: $ROLE_ARN"
else
    echo "❌ Failed to set GitHub secret"
    exit 1
fi

echo ""
echo "🎉 GitHub secrets setup completed!"
echo ""
echo "Next steps:"
echo "1. Push your changes to trigger the CI/CD pipeline"
echo "2. Monitor the build-and-deploy job in GitHub Actions"
echo "3. Verify that AWS authentication now works"
echo ""
echo "GitHub Actions will now be able to:"
echo "- Authenticate with AWS using OIDC"
echo "- Push Docker images to ECR"
echo "- Update ECS services"
