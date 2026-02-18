#!/bin/bash

################################################################################
# setup-env.sh - Environment Configuration Setup
# Configures environment variables for Terraform and deployment operations
# Usage: bash scripts/setup-env.sh
################################################################################

set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# ============================================================================
# Configuration
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_ROOT="${SCRIPT_DIR}"

# Determine environment
ENV="${ENV:-}"
if [ -z "$ENV" ]; then
    echo -e "${YELLOW}⚠️  ENV not set. Skipping setup.${NC}"
    exit 0
fi

# Validate environment
if [[ ! "$ENV" =~ ^(dev|staging|prod)$ ]]; then
    echo -e "${RED}❌ Invalid ENV: $ENV. Must be dev, staging, or prod${NC}"
    exit 1
fi

echo -e "${BLUE}📝 Setting up environment for: ${ENV}${NC}"

# ============================================================================
# AWS Configuration
# ============================================================================

# Set AWS region
AWS_REGION="${AWS_REGION:-us-east-1}"
export AWS_REGION

echo -e "${GREEN}✓${NC} AWS_REGION: $AWS_REGION"

# ============================================================================
# Terraform Configuration
# ============================================================================

export TF_ROOT="${PROJECT_ROOT}/infra"
export TF_VAR_environment="${ENV}"
export TF_VAR_aws_region="${AWS_REGION}"

# Terraform state backend configuration
case "$ENV" in
    staging)
        TERRAFORM_STATE_BUCKET="${TERRAFORM_STATE_BUCKET:-mypythonproject1-tf-state-staging}"
        TERRAFORM_LOCK_TABLE="${TERRAFORM_LOCK_TABLE:-terraform-locks-staging}"
        ;;
    prod)
        TERRAFORM_STATE_BUCKET="${TERRAFORM_STATE_BUCKET:-mypythonproject1-tf-state-prod}"
        TERRAFORM_LOCK_TABLE="${TERRAFORM_LOCK_TABLE:-terraform-locks-prod}"
        ;;
    dev)
        TERRAFORM_STATE_BUCKET="${TERRAFORM_STATE_BUCKET:-mypythonproject1-tf-state-dev}"
        TERRAFORM_LOCK_TABLE="${TERRAFORM_LOCK_TABLE:-terraform-locks-dev}"
        ;;
esac

export TERRAFORM_STATE_BUCKET
export TERRAFORM_LOCK_TABLE
export TF_VAR_state_bucket="${TERRAFORM_STATE_BUCKET}"
export TF_VAR_lock_table="${TERRAFORM_LOCK_TABLE}"

echo -e "${GREEN}✓${NC} TF_ROOT: $TF_ROOT"
echo -e "${GREEN}✓${NC} Terraform State Bucket: $TERRAFORM_STATE_BUCKET"
echo -e "${GREEN}✓${NC} Terraform Lock Table: $TERRAFORM_LOCK_TABLE"

# ============================================================================
# Docker Configuration
# ============================================================================

# ECR Registry
AWS_ACCOUNT_ID="${AWS_ACCOUNT_ID:-}"
ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
ECR_REPOSITORY_BACKEND="${ECR_REGISTRY}/mypythonproject1/backend"
ECR_REPOSITORY_FRONTEND="${ECR_REGISTRY}/mypythonproject1/frontend"

export ECR_REGISTRY
export ECR_REPOSITORY_BACKEND
export ECR_REPOSITORY_FRONTEND

echo -e "${GREEN}✓${NC} ECR_REGISTRY: $ECR_REGISTRY"

# ============================================================================
# ECS Configuration
# ============================================================================

case "$ENV" in
    staging)
        ECS_CLUSTER="mypythonproject1-cluster-staging"
        ECS_SERVICE_BACKEND="backend-service-staging"
        ECS_SERVICE_FRONTEND="frontend-service-staging"
        ;;
    prod)
        ECS_CLUSTER="mypythonproject1-cluster-prod"
        ECS_SERVICE_BACKEND="backend-service-prod"
        ECS_SERVICE_FRONTEND="frontend-service-prod"
        ;;
    dev)
        ECS_CLUSTER="mypythonproject1-cluster-dev"
        ECS_SERVICE_BACKEND="backend-service-dev"
        ECS_SERVICE_FRONTEND="frontend-service-dev"
        ;;
esac

export ECS_CLUSTER
export ECS_SERVICE_BACKEND
export ECS_SERVICE_FRONTEND

echo -e "${GREEN}✓${NC} ECS_CLUSTER: $ECS_CLUSTER"
echo -e "${GREEN}✓${NC} ECS_SERVICE_BACKEND: $ECS_SERVICE_BACKEND"
echo -e "${GREEN}✓${NC} ECS_SERVICE_FRONTEND: $ECS_SERVICE_FRONTEND"

# ============================================================================
# Secrets from GitHub Secrets (if running in CI/CD)
# ============================================================================

if [ -n "${GITHUB_ACTIONS:-}" ]; then
    echo -e "${BLUE}📝 Loading GitHub Secrets...${NC}"
    
    # AWS credentials (OIDC or stored credentials)
    export AWS_ROLE_TO_ASSUME="${AWS_ROLE_TO_ASSUME:-}"
    
    # Database secrets
    export TF_VAR_db_username="${DB_USERNAME:-}"
    export TF_VAR_db_password="${DB_PASSWORD:-}"
    
    # Application secrets
    export TF_VAR_jwt_secret_key="${JWT_SECRET_KEY:-}"
    export TF_VAR_jwt_algorithm="${JWT_ALGORITHM:-HS256}"
    
    echo -e "${GREEN}✓${NC} GitHub Secrets loaded"
fi

# ============================================================================
# Display Configuration Summary
# ============================================================================

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║       Environment Configuration Summary (${ENV})${NC}"
echo -e "${BLUE}╠════════════════════════════════════════════════════════════╣${NC}"
echo -e "${BLUE}║${NC} AWS Region:              ${AWS_REGION}"
echo -e "${BLUE}║${NC} Terraform Root:          ${TF_ROOT}"
echo -e "${BLUE}║${NC} State Backend:           ${TERRAFORM_STATE_BUCKET}"
echo -e "${BLUE}║${NC} State Lock Table:        ${TERRAFORM_LOCK_TABLE}"
echo -e "${BLUE}║${NC} ECR Registry:            ${ECR_REGISTRY}"
echo -e "${BLUE}║${NC} ECS Cluster:             ${ECS_CLUSTER}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${GREEN}✅ Environment setup complete for ${ENV}${NC}"
