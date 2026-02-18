#!/bin/bash

################################################################################
# validate-secrets.sh - Check for hardcoded secrets
# Usage: bash tools/validate-secrets.sh
################################################################################

set -euo pipefail

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "🔐 Scanning for hardcoded secrets..."
echo ""

# Patterns to search for
PATTERNS=(
    "PRIVATE_KEY"
    "AWS_SECRET_ACCESS_KEY"
    "DATABASE_PASSWORD"
    "JWT_SECRET"
    "API_KEY"
    "password.*=.*[\"\']"
    "secret.*=.*[\"\']"
)

FOUND=0

for pattern in "${PATTERNS[@]}"; do
    echo "🔍 Searching for: $pattern"
    
    # Search in common code files (exclude .git, node_modules, etc.)
    if grep -r "$pattern" "$ROOT_DIR" \
        --include="*.py" \
        --include="*.ts" \
        --include="*.js" \
        --include="*.sh" \
        --include="*.tf" \
        --exclude-dir=".git" \
        --exclude-dir="node_modules" \
        --exclude-dir="venv" \
        --exclude-dir="__pycache__" \
        --exclude="*.lock" \
        2>/dev/null || true; then
        
        echo -e "${YELLOW}⚠️  Found potential secret matching: $pattern${NC}"
        ((FOUND++))
    fi
done

echo ""

if [ $FOUND -eq 0 ]; then
    echo -e "${GREEN}✅ No obvious secrets found!${NC}"
    echo ""
    echo "Note: This is not a complete security check."
    echo "Always review code before committing."
    exit 0
else
    echo -e "${RED}⚠️  Potential secrets found. Review and remove before committing.${NC}"
    exit 1
fi
