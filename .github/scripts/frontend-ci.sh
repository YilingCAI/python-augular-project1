#!/usr/bin/env bash
###############################################################################
# frontend-ci.sh — Frontend TypeScript type-check and production build
#
# Runs the two build-validation steps that follow ESLint in the CI pipeline.
# ESLint is intentionally excluded here; it runs as a separate workflow step
# with continue-on-error: true so its outcome can be captured independently
# by the quality-gate job.
#
# Steps:
#   1. npm run type-check   TypeScript strict compilation check  (no emit)
#   2. npm run build        Vite / Angular production bundle
#
# Usage:
#   cd frontend && bash ../.github/scripts/frontend-ci.sh
#
# Expected CWD:   frontend/
# Dependencies:   npm  (installed by caller via actions/setup-node)
# Caller(s):      ci.yml — frontend-ci job  /  make frontend-build
###############################################################################
set -euo pipefail

echo "::group::TypeScript type-check"
npm run type-check
echo "::endgroup::"

echo "::group::Build"
npm run build
echo "::endgroup::"

echo "✅ Frontend type-check and build passed"
