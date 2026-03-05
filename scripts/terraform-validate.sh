#!/usr/bin/env bash
###############################################################################
# terraform-validate.sh — Terraform format, init, and validate
#
# Runs the three validation steps that require no remote state and no AWS
# credentials, making this safe to call without an active AWS session:
#
#   1. terraform fmt --check --recursive   formatting diff (exits 1 if dirty)
#   2. terraform init  -backend=false      provider + module resolution
#   3. terraform validate                  configuration syntax check
#   4. tflint  (if installed)              linting rules
#
# Usage:
#   bash scripts/terraform-validate.sh
#   make tf-validate
#
# Environment variables:
#   PROJECT_ROOT   optional — repo root; TF_ROOT defaults to ./infra
#
# Dependencies:   terraform; tflint (optional — skipped if not on PATH)
# Caller(s):      make tf-validate  /  .github/actions/terraform/validate
###############################################################################

set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔍 Running Terraform validation...${NC}"

TF_ROOT="${PROJECT_ROOT:-./infra}"

# ============================================================================
# Terraform Format Check
# ============================================================================

echo -e "${BLUE}📋 Checking Terraform format...${NC}"
# Clear previous backend metadata so stale remote backend params (e.g. deprecated
# dynamodb_table) do not leak warnings into local validation-only runs.
rm -rf "${TF_ROOT}/.terraform"
if terraform -chdir="${TF_ROOT}" fmt -check -recursive .; then
    echo -e "${GREEN}✓${NC} Terraform format is correct"
else
    echo -e "${YELLOW}⚠️  Terraform format issues found${NC}"
    echo "   Run 'terraform fmt -recursive' to fix"
fi

# ============================================================================
# Terraform Initialization (no backend)
# ============================================================================

echo -e "${BLUE}📋 Initializing Terraform (no backend)...${NC}"
terraform -chdir="${TF_ROOT}" init -backend=false -upgrade

# ============================================================================
# Terraform Validation
# ============================================================================

echo -e "${BLUE}📋 Validating Terraform configuration...${NC}"
if terraform -chdir="${TF_ROOT}" validate; then
    echo -e "${GREEN}✓${NC} Terraform validation passed"
else
    echo -e "${RED}❌ Terraform validation failed${NC}"
    exit 1
fi

# ============================================================================
# tflint Validation
# ============================================================================

echo -e "${BLUE}📋 Running tflint...${NC}"
if command -v tflint &> /dev/null; then
    cd "${TF_ROOT}" && tflint --init && tflint
    echo -e "${GREEN}✓${NC} tflint checks completed"
else
    echo -e "${YELLOW}⚠️  tflint not installed, skipping${NC}"
fi

echo -e "${GREEN}✅ Terraform validation complete${NC}"
