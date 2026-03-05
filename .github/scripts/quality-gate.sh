#!/usr/bin/env bash
###############################################################################
# quality-gate.sh — Evaluate CI quality gate and block on failures
#
# Reads the result of each required CI job (passed as environment variables
# containing the GitHub Actions job-result string) and exits non-zero if any
# mandatory gate has failed.  This script is the single blocking status check
# referenced by branch protection rules.
#
# Gate rules:
#   backend-ci and frontend-ci  must be "success"  (failure blocks the gate)
#   commitlint                  failure blocks; "skipped" is allowed on push
#   terraform-plan              failure blocks; "skipped" is allowed
#
# Usage:
#   RESULT_BACKEND=success RESULT_FRONTEND=success \
#   RESULT_COMMITLINT=success RESULT_TF_PLAN=skipped \
#     bash .github/scripts/quality-gate.sh
#
# Environment variables (GitHub Actions job result strings):
#   RESULT_COMMITLINT   success | failure | cancelled | skipped
#   RESULT_BACKEND      success | failure | cancelled | skipped
#   RESULT_FRONTEND     success | failure | cancelled | skipped
#   RESULT_TF_PLAN      success | failure | cancelled | skipped
#
# Dependencies:   bash 4+
# Caller(s):      ci.yml — quality-gate job
###############################################################################
set -euo pipefail

echo "Quality Gate Results:"
printf "  %-20s %s\n" "commitlint:"  "${RESULT_COMMITLINT:-skipped}"
printf "  %-20s %s\n" "backend-ci:"  "${RESULT_BACKEND:-skipped}"
printf "  %-20s %s\n" "frontend-ci:" "${RESULT_FRONTEND:-skipped}"
printf "  %-20s %s\n" "tf-plan:"     "${RESULT_TF_PLAN:-skipped}"

fail=0

# Hard failures — these must pass
for result in "${RESULT_BACKEND:-}" "${RESULT_FRONTEND:-}"; do
  if [[ "${result}" == "failure" ]]; then
    echo "❌ Required job failed (backend-ci or frontend-ci)"
    fail=1
  fi
done

# Commitlint only runs on PRs; a 'skipped' result on push is fine
if [[ "${RESULT_COMMITLINT:-}" == "failure" ]]; then
  echo "❌ Commitlint failed"
  fail=1
fi

# Terraform plan failure blocks PRs with infra changes
if [[ "${RESULT_TF_PLAN:-}" == "failure" ]]; then
  echo "❌ Terraform plan failed"
  fail=1
fi

if [[ "${fail}" -eq 1 ]]; then
  exit 1
fi

echo "✅ All gates passed"
