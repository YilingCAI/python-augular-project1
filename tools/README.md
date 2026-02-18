# DevOps Tools

Utility scripts and helpers for DevOps operations.

## Available Tools

### lint-scripts.sh
Validates all shell scripts using shellcheck.

```bash
bash tools/lint-scripts.sh
```

**Prerequisites**: `shellcheck`
```bash
# Install
brew install shellcheck
```

### validate-secrets.sh
Scans codebase for hardcoded secrets.

```bash
bash tools/validate-secrets.sh
```

**What it checks**:
- PRIVATE_KEY patterns
- AWS_SECRET_ACCESS_KEY
- DATABASE_PASSWORD
- JWT_SECRET
- API_KEY references
- Password and secret assignments

### generate-tfvars.sh (example)
Generate Terraform variables from templates.

```bash
bash tools/generate-tfvars.sh staging
```

## Usage in CI/CD

All tools are automatically run in GitHub Actions:

```yaml
# .github/workflows/validate.yml
- name: Lint scripts
  run: bash tools/lint-scripts.sh

- name: Check for secrets
  run: bash tools/validate-secrets.sh
```

## Creating New Tools

Tools should follow this pattern:

```bash
#!/bin/bash

################################################################################
# tool-name.sh - Brief description
# Usage: bash tools/tool-name.sh [args]
################################################################################

set -euo pipefail

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Implementation here

# Always exit with 0 (success) or 1 (failure)
exit 0
```

## Related Documentation

- [README.md](../README.md) - Project overview
- [Makefile](../Makefile) - All available targets
- [scripts/](../scripts/) - DevOps scripts
