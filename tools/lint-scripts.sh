#!/bin/bash

################################################################################
# lint-scripts.sh - Validate all shell scripts
# Usage: bash tools/lint-scripts.sh
################################################################################

set -euo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/scripts"

echo "🔍 Linting shell scripts in: $SCRIPTS_DIR"
echo ""

# Check if shellcheck is installed
if ! command -v shellcheck &> /dev/null; then
    echo "❌ shellcheck not found. Install with:"
    echo "   brew install shellcheck"
    exit 1
fi

ERRORS=0

for script in "$SCRIPTS_DIR"/*.sh; do
    if [ -f "$script" ]; then
        echo "📝 Checking: $(basename "$script")"
        
        if shellcheck "$script"; then
            echo -e "  ${GREEN}✓ OK${NC}"
        else
            echo -e "  ${RED}✗ FAILED${NC}"
            ((ERRORS++))
        fi
        echo ""
    fi
done

if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}✅ All scripts passed linting!${NC}"
    exit 0
else
    echo -e "${RED}❌ $ERRORS script(s) failed linting${NC}"
    exit 1
fi
