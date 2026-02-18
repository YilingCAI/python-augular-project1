#!/bin/bash

################################################################################
# docker-build.sh - Build and Push Docker Images
# Builds Docker images and optionally pushes to ECR
# Usage: ENV=staging bash scripts/docker-build.sh [push]
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

PUSH_FLAG="${1:-}"
DO_PUSH=false
if [ "$PUSH_FLAG" = "push" ]; then
    DO_PUSH=true
fi

echo -e "${BLUE}🐳 Building Docker images for ${ENV}${NC}"

# ============================================================================
# Setup
# ============================================================================

PROJECT_ROOT="${PROJECT_ROOT:-.}"
IMAGE_TAG="${IMAGE_TAG:-$(git rev-parse --short HEAD 2>/dev/null || echo 'latest')}"
BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ')

echo -e "${BLUE}📝 Configuration:${NC}"
echo -e "${GREEN}✓${NC} Environment:   ${ENV}"
echo -e "${GREEN}✓${NC} Image Tag:      ${IMAGE_TAG}"
echo -e "${GREEN}✓${NC} Build Date:     ${BUILD_DATE}"
echo ""

# ============================================================================
# ECR Login (if pushing)
# ============================================================================

if [ "$DO_PUSH" = true ]; then
    echo -e "${BLUE}🔐 Logging in to ECR...${NC}"
    
    if [ -z "${ECR_REGISTRY:-}" ]; then
        echo -e "${RED}❌ ECR_REGISTRY not set${NC}"
        exit 1
    fi
    
    # Get authentication token
    aws ecr get-login-password --region "${AWS_REGION}" | \
        docker login --username AWS --password-stdin "${ECR_REGISTRY}"
    
    echo -e "${GREEN}✓${NC} ECR login successful"
fi

# ============================================================================
# Build Backend Image
# ============================================================================

echo -e "${BLUE}🔨 Building backend image...${NC}"

BACKEND_IMAGE="${ECR_REPOSITORY_BACKEND}:${IMAGE_TAG}"
BACKEND_IMAGE_LATEST="${ECR_REPOSITORY_BACKEND}:latest"

docker build \
    -t "${BACKEND_IMAGE}" \
    -t "${BACKEND_IMAGE_LATEST}" \
    --build-arg BUILD_DATE="${BUILD_DATE}" \
    --build-arg VCS_REF="${IMAGE_TAG}" \
    --build-arg VERSION="${ENV}" \
    -f backend/Dockerfile \
    backend/

echo -e "${GREEN}✓${NC} Backend image built: ${BACKEND_IMAGE}"

# ============================================================================
# Build Frontend Image
# ============================================================================

echo -e "${BLUE}🔨 Building frontend image...${NC}"

FRONTEND_IMAGE="${ECR_REPOSITORY_FRONTEND}:${IMAGE_TAG}"
FRONTEND_IMAGE_LATEST="${ECR_REPOSITORY_FRONTEND}:latest"

docker build \
    -t "${FRONTEND_IMAGE}" \
    -t "${FRONTEND_IMAGE_LATEST}" \
    --build-arg BUILD_DATE="${BUILD_DATE}" \
    --build-arg VCS_REF="${IMAGE_TAG}" \
    --build-arg VERSION="${ENV}" \
    -f frontend/Dockerfile \
    frontend/

echo -e "${GREEN}✓${NC} Frontend image built: ${FRONTEND_IMAGE}"

# ============================================================================
# Vulnerability Scanning
# ============================================================================

if command -v trivy &> /dev/null; then
    echo -e "${BLUE}🔒 Running Trivy vulnerability scan...${NC}"
    
    trivy image --severity HIGH,CRITICAL "${BACKEND_IMAGE}" || true
    trivy image --severity HIGH,CRITICAL "${FRONTEND_IMAGE}" || true
    
    echo -e "${GREEN}✓${NC} Trivy scan completed"
else
    echo -e "${YELLOW}⚠️  Trivy not installed, skipping scan${NC}"
fi

# ============================================================================
# Push to ECR
# ============================================================================

if [ "$DO_PUSH" = true ]; then
    echo -e "${BLUE}📤 Pushing images to ECR...${NC}"
    
    # Push backend
    echo "Pushing backend image..."
    docker push "${BACKEND_IMAGE}"
    docker push "${BACKEND_IMAGE_LATEST}"
    echo -e "${GREEN}✓${NC} Backend image pushed"
    
    # Push frontend
    echo "Pushing frontend image..."
    docker push "${FRONTEND_IMAGE}"
    docker push "${FRONTEND_IMAGE_LATEST}"
    echo -e "${GREEN}✓${NC} Frontend image pushed"
    
    # Save image URIs for downstream use
    echo "${BACKEND_IMAGE}" > /tmp/backend_image_uri.txt
    echo "${FRONTEND_IMAGE}" > /tmp/frontend_image_uri.txt
fi

# ============================================================================
# Summary
# ============================================================================

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║              Docker Build Summary${NC}"
echo -e "${BLUE}╠════════════════════════════════════════════════════════════╣${NC}"
echo -e "${BLUE}║${NC} Environment:             ${ENV}"
echo -e "${BLUE}║${NC} Image Tag:               ${IMAGE_TAG}"
echo -e "${BLUE}║${NC} Backend Image:           ${BACKEND_IMAGE}"
echo -e "${BLUE}║${NC} Frontend Image:          ${FRONTEND_IMAGE}"
if [ "$DO_PUSH" = true ]; then
    echo -e "${BLUE}║${NC} Status:                  ✅ Built & Pushed to ECR"
else
    echo -e "${BLUE}║${NC} Status:                  ✅ Built (Local)"
fi
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

if [ "$DO_PUSH" = true ]; then
    echo -e "${GREEN}✅ Docker images built and pushed${NC}"
    echo -e "${YELLOW}📝 Next step: make ecs-deploy ENV=${ENV} IMAGE_TAG=${IMAGE_TAG}${NC}"
else
    echo -e "${GREEN}✅ Docker images built${NC}"
    echo -e "${YELLOW}📝 To push to ECR: make docker-push ENV=${ENV}${NC}"
fi
