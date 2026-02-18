#!/bin/bash

################################################################################
# terraform-apply.sh - Apply Terraform Changes
# Applies infrastructure changes from generated plan
# Usage: ENV=staging bash scripts/terraform-apply.sh
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

if [ -z "${ENV:-}" ]; then
    echo -e "${RED}❌ ENV not set${NC}"
    exit 1
fi

echo -e "${BLUE}🚀 Terraform Apply for ${ENV}${NC}"

# ============================================================================
# Setup
# ============================================================================

TF_ROOT="${TF_ROOT:-./infra}"
TFPLAN_FILE="/tmp/tf-plans/tfplan.${ENV}"
TFVARS_FILE="${TF_ROOT}/envs/${ENV}.tfvars"

# Check if plan exists from terraform-plan.sh
if [ ! -f "$TFPLAN_FILE" ]; then
    echo -e "${YELLOW}⚠️  Plan not found: $TFPLAN_FILE${NC}"
    echo "   Running terraform plan first..."
    bash scripts/terraform-plan.sh
fi

# ============================================================================
# Production Confirmation
# ============================================================================

if [ "$ENV" = "prod" ]; then
    echo -e "${RED}🚨 PRODUCTION ENVIRONMENT 🚨${NC}"
    echo -e "${YELLOW}This will modify PRODUCTION infrastructure${NC}"
    echo ""
    read -p "Type 'yes' to continue with production apply: " confirm
    if [ "$confirm" != "yes" ]; then
        echo -e "${YELLOW}❌ Apply cancelled${NC}"
        exit 1
    fi
fi

# ============================================================================
# Terraform Backend Configuration
# ============================================================================

echo -e "${BLUE}📝 Configuring Terraform backend...${NC}"

cat > "${TF_ROOT}/backend-config.hcl" << EOF
bucket         = "${TERRAFORM_STATE_BUCKET}"
key            = "terraform/${ENV}/terraform.tfstate"
region         = "${AWS_REGION}"
dynamodb_table = "${TERRAFORM_LOCK_TABLE}"
encrypt        = true
EOF

# ============================================================================
# Terraform Initialization
# ============================================================================

echo -e "${BLUE}📋 Initializing Terraform...${NC}"
terraform -chdir="${TF_ROOT}" init \
    -backend-config="backend-config.hcl" \
    -upgrade

# ============================================================================
# Terraform Apply
# ============================================================================

echo -e "${BLUE}🔄 Applying Terraform changes...${NC}"
terraform -chdir="${TF_ROOT}" apply \
    -input=false \
    -lock=true \
    -lock-timeout=5m \
    "${TFPLAN_FILE}"

echo -e "${GREEN}✓${NC} Terraform apply completed"

# ============================================================================
# Export Outputs
# ============================================================================

echo -e "${BLUE}📤 Exporting Terraform outputs...${NC}"

# Create output file
OUTPUT_FILE="/tmp/tf-outputs-${ENV}.json"
terraform -chdir="${TF_ROOT}" output -json > "${OUTPUT_FILE}"

echo -e "${GREEN}✓${NC} Outputs exported to: ${OUTPUT_FILE}"

# Extract key outputs
if command -v jq &> /dev/null; then
    ECS_CLUSTER=$(jq -r '.ecs_cluster.value // empty' "${OUTPUT_FILE}")
    ALB_ENDPOINT=$(jq -r '.alb_endpoint.value // empty' "${OUTPUT_FILE}")
    
    if [ -n "$ECS_CLUSTER" ]; then
        export ECS_CLUSTER
        echo -e "${BLUE}║${NC} ECS Cluster:             ${ECS_CLUSTER}"
    fi
    
    if [ -n "$ALB_ENDPOINT" ]; then
        export ALB_ENDPOINT
        echo -e "${BLUE}║${NC} ALB Endpoint:            ${ALB_ENDPOINT}"
    fi
fi

# ============================================================================
# Summary
# ============================================================================

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║           Terraform Apply Summary${NC}"
echo -e "${BLUE}╠════════════════════════════════════════════════════════════╣${NC}"
echo -e "${BLUE}║${NC} Environment:             ${ENV}"
echo -e "${BLUE}║${NC} State Backend:           ${TERRAFORM_STATE_BUCKET}/${ENV}"
echo -e "${BLUE}║${NC} Status:                  ✅ Applied"
echo -e "${BLUE}║${NC} Outputs File:            ${OUTPUT_FILE}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${GREEN}✅ Terraform apply complete${NC}"
echo -e "${YELLOW}📝 Next step: make ecs-deploy ENV=${ENV} IMAGE_TAG=...${NC}"
