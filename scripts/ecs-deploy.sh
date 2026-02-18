#!/bin/bash

################################################################################
# ecs-deploy.sh - Deploy to ECS Fargate
# Updates ECS services with new task definitions and images
# Usage: ENV=staging IMAGE_TAG=sha-abc123 bash scripts/ecs-deploy.sh
################################################################################

set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# ============================================================================
# Validation
# ============================================================================

if [ -z "${ENV:-}" ] || [ -z "${IMAGE_TAG:-}" ]; then
    echo -e "${RED}❌ Missing parameters${NC}"
    echo "   Usage: ENV=staging IMAGE_TAG=sha-abc123 bash scripts/ecs-deploy.sh"
    exit 1
fi

echo -e "${BLUE}🚀 ECS Deployment for ${ENV}${NC}"

# ============================================================================
# Setup
# ============================================================================

BACKEND_IMAGE_URI="${ECR_REPOSITORY_BACKEND}:${IMAGE_TAG}"
FRONTEND_IMAGE_URI="${ECR_REPOSITORY_FRONTEND}:${IMAGE_TAG}"

# Load Terraform outputs if available
OUTPUTS_FILE="/tmp/tf-outputs-${ENV}.json"
if [ -f "$OUTPUTS_FILE" ]; then
    if command -v jq &> /dev/null; then
        ECS_CLUSTER=$(jq -r '.ecs_cluster.value // empty' "$OUTPUTS_FILE")
        ECS_SERVICE_BACKEND=$(jq -r '.backend_service_name.value // empty' "$OUTPUTS_FILE")
        ECS_SERVICE_FRONTEND=$(jq -r '.frontend_service_name.value // empty' "$OUTPUTS_FILE")
    fi
fi

# Validate cluster and services
if [ -z "${ECS_CLUSTER:-}" ]; then
    echo -e "${RED}❌ ECS_CLUSTER not found${NC}"
    exit 1
fi

if [ -z "${ECS_SERVICE_BACKEND:-}" ]; then
    echo -e "${RED}❌ ECS_SERVICE_BACKEND not found${NC}"
    exit 1
fi

if [ -z "${ECS_SERVICE_FRONTEND:-}" ]; then
    echo -e "${RED}❌ ECS_SERVICE_FRONTEND not found${NC}"
    exit 1
fi

echo -e "${BLUE}📝 Configuration:${NC}"
echo -e "${GREEN}✓${NC} Environment:             ${ENV}"
echo -e "${GREEN}✓${NC} ECS Cluster:             ${ECS_CLUSTER}"
echo -e "${GREEN}✓${NC} Backend Service:         ${ECS_SERVICE_BACKEND}"
echo -e "${GREEN}✓${NC} Frontend Service:        ${ECS_SERVICE_FRONTEND}"
echo -e "${GREEN}✓${NC} Backend Image:           ${BACKEND_IMAGE_URI}"
echo -e "${GREEN}✓${NC} Frontend Image:          ${FRONTEND_IMAGE_URI}"
echo ""

# ============================================================================
# Pre-deployment Checks
# ============================================================================

echo -e "${BLUE}🔍 Running pre-deployment checks...${NC}"

# Check cluster exists
if ! aws ecs describe-clusters \
    --cluster "${ECS_CLUSTER}" \
    --region "${AWS_REGION}" \
    --query 'clusters[0].clusterArn' \
    --output text | grep -q "arn:aws"; then
    echo -e "${RED}❌ ECS cluster not found: ${ECS_CLUSTER}${NC}"
    exit 1
fi

# Check services exist
if ! aws ecs describe-services \
    --cluster "${ECS_CLUSTER}" \
    --services "${ECS_SERVICE_BACKEND}" "${ECS_SERVICE_FRONTEND}" \
    --region "${AWS_REGION}" \
    --query 'services[*].serviceName' \
    --output text | grep -q "${ECS_SERVICE_BACKEND}"; then
    echo -e "${RED}❌ Backend service not found: ${ECS_SERVICE_BACKEND}${NC}"
    exit 1
fi

echo -e "${GREEN}✓${NC} Pre-deployment checks passed"

# ============================================================================
# Deploy Backend Service
# ============================================================================

echo -e "${BLUE}🚀 Deploying backend service...${NC}"

# Get current task definition
BACKEND_TASK_DEF=$(aws ecs describe-services \
    --cluster "${ECS_CLUSTER}" \
    --services "${ECS_SERVICE_BACKEND}" \
    --region "${AWS_REGION}" \
    --query 'services[0].taskDefinition' \
    --output text)

# Create new task definition with updated image
aws ecs describe-task-definition \
    --task-definition "${BACKEND_TASK_DEF}" \
    --region "${AWS_REGION}" \
    --query 'taskDefinition' \
    | jq \
        --arg IMAGE "${BACKEND_IMAGE_URI}" \
        '.containerDefinitions[0].image = $IMAGE' \
    | jq 'del(.taskDefinitionArn, .revision, .status, .requiresAttributes, .compatibilities, .registeredAt, .registeredBy)' \
    > /tmp/backend-task-def.json

# Register new task definition
NEW_BACKEND_TASK_DEF=$(aws ecs register-task-definition \
    --region "${AWS_REGION}" \
    --cli-input-json file:///tmp/backend-task-def.json \
    --query 'taskDefinition.taskDefinitionArn' \
    --output text)

echo -e "${GREEN}✓${NC} New backend task definition: ${NEW_BACKEND_TASK_DEF}"

# Update service
aws ecs update-service \
    --cluster "${ECS_CLUSTER}" \
    --service "${ECS_SERVICE_BACKEND}" \
    --task-definition "${NEW_BACKEND_TASK_DEF}" \
    --force-new-deployment \
    --region "${AWS_REGION}" \
    --query 'service.serviceName' \
    --output text

echo -e "${GREEN}✓${NC} Backend service updated"

# ============================================================================
# Deploy Frontend Service
# ============================================================================

echo -e "${BLUE}🚀 Deploying frontend service...${NC}"

# Get current task definition
FRONTEND_TASK_DEF=$(aws ecs describe-services \
    --cluster "${ECS_CLUSTER}" \
    --services "${ECS_SERVICE_FRONTEND}" \
    --region "${AWS_REGION}" \
    --query 'services[0].taskDefinition' \
    --output text)

# Create new task definition with updated image
aws ecs describe-task-definition \
    --task-definition "${FRONTEND_TASK_DEF}" \
    --region "${AWS_REGION}" \
    --query 'taskDefinition' \
    | jq \
        --arg IMAGE "${FRONTEND_IMAGE_URI}" \
        '.containerDefinitions[0].image = $IMAGE' \
    | jq 'del(.taskDefinitionArn, .revision, .status, .requiresAttributes, .compatibilities, .registeredAt, .registeredBy)' \
    > /tmp/frontend-task-def.json

# Register new task definition
NEW_FRONTEND_TASK_DEF=$(aws ecs register-task-definition \
    --region "${AWS_REGION}" \
    --cli-input-json file:///tmp/frontend-task-def.json \
    --query 'taskDefinition.taskDefinitionArn' \
    --output text)

echo -e "${GREEN}✓${NC} New frontend task definition: ${NEW_FRONTEND_TASK_DEF}"

# Update service
aws ecs update-service \
    --cluster "${ECS_CLUSTER}" \
    --service "${ECS_SERVICE_FRONTEND}" \
    --task-definition "${NEW_FRONTEND_TASK_DEF}" \
    --force-new-deployment \
    --region "${AWS_REGION}" \
    --query 'service.serviceName' \
    --output text

echo -e "${GREEN}✓${NC} Frontend service updated"

# ============================================================================
# Wait for Deployment
# ============================================================================

echo -e "${BLUE}⏳ Waiting for deployment to stabilize...${NC}"

# Backend
aws ecs wait services-stable \
    --cluster "${ECS_CLUSTER}" \
    --services "${ECS_SERVICE_BACKEND}" \
    --region "${AWS_REGION}"

echo -e "${GREEN}✓${NC} Backend deployment stable"

# Frontend
aws ecs wait services-stable \
    --cluster "${ECS_CLUSTER}" \
    --services "${ECS_SERVICE_FRONTEND}" \
    --region "${AWS_REGION}"

echo -e "${GREEN}✓${NC} Frontend deployment stable"

# ============================================================================
# Post-deployment Verification
# ============================================================================

echo -e "${BLUE}🔍 Verifying deployment...${NC}"

# Backend verification
BACKEND_RUNNING=$(aws ecs describe-services \
    --cluster "${ECS_CLUSTER}" \
    --services "${ECS_SERVICE_BACKEND}" \
    --region "${AWS_REGION}" \
    --query 'services[0].runningCount' \
    --output text)

BACKEND_DESIRED=$(aws ecs describe-services \
    --cluster "${ECS_CLUSTER}" \
    --services "${ECS_SERVICE_BACKEND}" \
    --region "${AWS_REGION}" \
    --query 'services[0].desiredCount' \
    --output text)

# Frontend verification
FRONTEND_RUNNING=$(aws ecs describe-services \
    --cluster "${ECS_CLUSTER}" \
    --services "${ECS_SERVICE_FRONTEND}" \
    --region "${AWS_REGION}" \
    --query 'services[0].runningCount' \
    --output text)

FRONTEND_DESIRED=$(aws ecs describe-services \
    --cluster "${ECS_CLUSTER}" \
    --services "${ECS_SERVICE_FRONTEND}" \
    --region "${AWS_REGION}" \
    --query 'services[0].desiredCount' \
    --output text)

echo -e "${GREEN}✓${NC} Backend: ${BACKEND_RUNNING}/${BACKEND_DESIRED} tasks running"
echo -e "${GREEN}✓${NC} Frontend: ${FRONTEND_RUNNING}/${FRONTEND_DESIRED} tasks running"

# ============================================================================
# Summary
# ============================================================================

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║            ECS Deployment Summary${NC}"
echo -e "${BLUE}╠════════════════════════════════════════════════════════════╣${NC}"
echo -e "${BLUE}║${NC} Environment:             ${ENV}"
echo -e "${BLUE}║${NC} Cluster:                 ${ECS_CLUSTER}"
echo -e "${BLUE}║${NC} Backend Task Def:        ${NEW_BACKEND_TASK_DEF##*/}"
echo -e "${BLUE}║${NC} Frontend Task Def:       ${NEW_FRONTEND_TASK_DEF##*/}"
echo -e "${BLUE}║${NC} Status:                  ✅ Deployed & Stable"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${GREEN}✅ ECS deployment complete${NC}"
