#!/usr/bin/env bash
###############################################################################
# backend-test.sh — Backend lint and full test suite
#
# Runs four sequential checks against the backend Python package:
#   1. ruff check             PEP 8 / import / style linting
#   2. ruff format --check    formatting diff  (non-destructive, fails if dirty)
#   3. pytest unit            fast unit tests  (no DB) with coverage report
#   4. pytest integration     database-backed integration tests with coverage
#
# JUnit XML results are written to:
#   backend/test-results-unit.xml
#   backend/test-results-integration.xml
# These are picked up by the publish-test-results composite action.
#
# Usage:
#   cd backend && bash ../.github/scripts/backend-test.sh
#
# Expected CWD:   backend/
# Dependencies:   poetry  (installs ruff, pytest, pytest-cov)
# Caller(s):      ci.yml — backend-ci job  /  make lint  /  make test
###############################################################################
set -euo pipefail

echo "::group::Ruff lint"
poetry run ruff check app/ --output-format=github
poetry run ruff format app/ --check
echo "::endgroup::"

echo "::group::Unit tests"
poetry run pytest tests/unit -m unit -v \
  --cov=app --cov-report=xml --cov-report=html \
  --junitxml=test-results-unit.xml \
  --maxfail=5 --tb=short
echo "::endgroup::"

echo "::group::Integration tests"
poetry run pytest tests/integration -m integration -v \
  --cov=app --cov-report=xml --cov-report=html \
  --junitxml=test-results-integration.xml \
  --maxfail=5 --tb=short
echo "::endgroup::"

echo "✅ Backend tests passed"
