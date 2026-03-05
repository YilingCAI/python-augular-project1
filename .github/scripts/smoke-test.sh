#!/usr/bin/env bash
###############################################################################
# smoke-test.sh — Post-deployment health-check smoke test
#
# Waits for the application to warm up, then probes the /health endpoint
# with configurable retries.  Exits non-zero if the endpoint does not return
# HTTP 200 within the allotted attempts, causing the calling workflow job to
# fail and halting any subsequent deployment steps.
#
# Usage:
#   APP_URL=https://your-app.example.com bash .github/scripts/smoke-test.sh
#   make smoke-test APP_URL=https://your-app.example.com
#
# Environment variables:
#   APP_URL       REQUIRED — base URL of the deployed application
#   WARMUP_SECS   optional — seconds to wait before first probe  (default: 15)
#   MAX_RETRIES   optional — number of probe attempts             (default: 3)
#   RETRY_DELAY   optional — seconds between retries              (default: 10)
#
# Dependencies:   curl
# Caller(s):      .github/workflows/_smoke-test.yml  /  make smoke-test
###############################################################################
set -euo pipefail

: "${APP_URL:?APP_URL must be set}"

WARMUP_SECS="${WARMUP_SECS:-15}"
MAX_RETRIES="${MAX_RETRIES:-3}"
RETRY_DELAY="${RETRY_DELAY:-10}"

echo "⏳ Waiting ${WARMUP_SECS}s for service to warm up..."
sleep "${WARMUP_SECS}"

STATUS="000"
for i in $(seq 1 "${MAX_RETRIES}"); do
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" "${APP_URL}/health" --max-time 15 || echo "000")
  echo "Attempt ${i}/${MAX_RETRIES}: HTTP ${STATUS}"
  [[ "${STATUS}" == "200" ]] && break
  if [[ "${i}" -lt "${MAX_RETRIES}" ]]; then
    echo "Retrying in ${RETRY_DELAY}s..."
    sleep "${RETRY_DELAY}"
  fi
done

if [[ "${STATUS}" != "200" ]]; then
  echo "❌ Health check failed after ${MAX_RETRIES} attempts (last HTTP status: ${STATUS})"
  exit 1
fi

echo "✅ Smoke test passed (HTTP 200)"
