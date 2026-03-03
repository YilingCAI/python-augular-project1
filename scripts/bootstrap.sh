#!/usr/bin/env bash
###############################################################################
# bootstrap.sh — One-time AWS infrastructure bootstrap
#
# Creates every AWS resource required before the first CI/CD run.  Safe to
# re-run; all steps check for existing resources before creating them.
#
# Resources created:
#   - S3 bucket          Terraform remote state (versioned, AES-256 encrypted,
#                        public-access blocked)
#   - DynamoDB table     Terraform state locking  (terraform-locks)
#   - ECR repositories   mypythonproject1/backend  +  mypythonproject1/frontend
#   - IAM OIDC provider  token.actions.githubusercontent.com
#   - IAM role           GitHubActionsRole  (assumed by GitHub Actions via OIDC)
#   - IAM inline policy  GitHubActionsPolicy  (ECR, ECS, EC2, ALB, S3, ...)
#
# After completion the script prints the exact `gh secret set` commands that
# must be run before workflows will succeed.
#
# Usage:
#   bash scripts/bootstrap.sh
#   make bootstrap
#
# Environment variables:
#   AWS_REGION   optional — target AWS region  (default: us-east-1)
#
# Dependencies:   aws (AWS CLI v2)
# Optional:       gh (GitHub CLI) for convenience when setting secrets
# Caller(s):      make bootstrap
###############################################################################

set -e

echo "🚀 Starting CI/CD Bootstrap..."

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get AWS Account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION=${AWS_REGION:-us-east-1}

echo -e "${YELLOW}AWS Account: ${AWS_ACCOUNT_ID}${NC}"
echo -e "${YELLOW}AWS Region: ${AWS_REGION}${NC}"

# Check prerequisites
echo -e "\n${YELLOW}Checking prerequisites...${NC}"

if ! command -v aws &> /dev/null; then
  echo -e "${RED}❌ AWS CLI not found. Install it first.${NC}"
  exit 1
fi

if ! command -v terraform &> /dev/null; then
  echo -e "${YELLOW}⚠ Terraform not found. Continuing bootstrap (Terraform CLI not required for this script).${NC}"
fi

if ! command -v gh &> /dev/null; then
  echo -e "${YELLOW}⚠ GitHub CLI (gh) not found. Continuing; set GitHub secrets manually in repo settings.${NC}"
fi

echo -e "${GREEN}✓ All prerequisites found${NC}"

# Create S3 bucket for Terraform state
echo -e "\n${YELLOW}Creating S3 bucket for Terraform state...${NC}"
S3_BUCKET="terraform-state-${AWS_ACCOUNT_ID}"

if aws s3 ls "s3://${S3_BUCKET}" 2>/dev/null; then
  echo -e "${YELLOW}⚠ S3 bucket already exists${NC}"
else
  aws s3api create-bucket \
    --bucket "${S3_BUCKET}" \
    --region "${AWS_REGION}" \
    $(if [ "$AWS_REGION" != "us-east-1" ]; then echo "--create-bucket-configuration LocationConstraint=$AWS_REGION"; fi)
  
  # Enable versioning
  aws s3api put-bucket-versioning \
    --bucket "${S3_BUCKET}" \
    --versioning-configuration Status=Enabled
  
  # Enable encryption
  aws s3api put-bucket-encryption \
    --bucket "${S3_BUCKET}" \
    --server-side-encryption-configuration '{
      "Rules": [{
        "ApplyServerSideEncryptionByDefault": {
          "SSEAlgorithm": "AES256"
        }
      }]
    }'
  
  # Block public access
  aws s3api put-public-access-block \
    --bucket "${S3_BUCKET}" \
    --public-access-block-configuration \
    "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
  
  echo -e "${GREEN}✓ S3 bucket created${NC}"
fi

# Create DynamoDB table for state locking
echo -e "\n${YELLOW}Creating DynamoDB table for state locking...${NC}"
LOCK_TABLE="terraform-locks"

if aws dynamodb describe-table --table-name "${LOCK_TABLE}" 2>/dev/null; then
  echo -e "${YELLOW}⚠ DynamoDB table already exists${NC}"
else
  aws dynamodb create-table \
    --table-name "${LOCK_TABLE}" \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
    --region "${AWS_REGION}"

  aws dynamodb wait table-exists --table-name "${LOCK_TABLE}"
  echo -e "${GREEN}✓ DynamoDB table created${NC}"
fi

# Create ECR repositories
echo -e "\n${YELLOW}Creating ECR repositories...${NC}"

for service in backend frontend; do
  REPO_NAME="mypythonproject1/$service"
  
  if aws ecr describe-repositories --repository-names "${REPO_NAME}" 2>/dev/null; then
    echo -e "${YELLOW}⚠ ECR repository ${REPO_NAME} already exists${NC}"
  else
    aws ecr create-repository \
      --repository-name "${REPO_NAME}" \
      --encryption-configuration encryptionType=AES256 \
      --image-scanning-configuration scanOnPush=true \
      --region "${AWS_REGION}"
    
    echo -e "${GREEN}✓ ECR repository ${REPO_NAME} created${NC}"
  fi
done

# Create IAM role for GitHub Actions OIDC
echo -e "\n${YELLOW}Creating IAM role for GitHub Actions OIDC...${NC}"

# Check if OIDC provider exists
if aws iam list-open-id-connect-providers | grep -q "token.actions.githubusercontent.com"; then
  echo -e "${YELLOW}⚠ OIDC provider already exists${NC}"
else
  aws iam create-open-id-connect-provider \
    --url https://token.actions.githubusercontent.com \
    --client-id-list sts.amazonaws.com \
    --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
  
  echo -e "${GREEN}✓ OIDC provider created${NC}"
fi

# Create trust policy
cat > /tmp/trust-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::${AWS_ACCOUNT_ID}:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:*/*:*"
        }
      }
    }
  ]
}
EOF

# Create IAM role
if aws iam get-role --role-name GitHubActionsRole 2>/dev/null; then
  echo -e "${YELLOW}⚠ IAM role GitHubActionsRole already exists${NC}"
else
  aws iam create-role \
    --role-name GitHubActionsRole \
    --assume-role-policy-document file:///tmp/trust-policy.json
  
  echo -e "${GREEN}✓ IAM role created${NC}"
fi

# Create policy
cat > /tmp/github-actions-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ECRAccess",
      "Effect": "Allow",
      "Action": [
        "ecr:*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "ECSAccess",
      "Effect": "Allow",
      "Action": [
        "ecs:*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "EC2Access",
      "Effect": "Allow",
      "Action": [
        "ec2:*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "ALBAccess",
      "Effect": "Allow",
      "Action": [
        "elasticloadbalancing:*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "S3Access",
      "Effect": "Allow",
      "Action": [
        "s3:*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "DynamoDBAccess",
      "Effect": "Allow",
      "Action": [
        "dynamodb:*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "LogsAccess",
      "Effect": "Allow",
      "Action": [
        "logs:*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "CloudWatchAccess",
      "Effect": "Allow",
      "Action": [
        "cloudwatch:*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "IAMPassRole",
      "Effect": "Allow",
      "Action": [
        "iam:PassRole"
      ],
      "Resource": "*"
    }
  ]
}
EOF

aws iam put-role-policy \
  --role-name GitHubActionsRole \
  --policy-name GitHubActionsPolicy \
  --policy-document file:///tmp/github-actions-policy.json

echo -e "${GREEN}✓ IAM policy attached${NC}"

# Summary
echo -e "\n${GREEN}✅ Bootstrap complete!${NC}"

echo -e "\n${YELLOW}Next steps:${NC}"
echo "1. Set GitHub secrets:"
echo "   gh secret set AWS_ROLE_TO_ASSUME --body \"arn:aws:iam::${AWS_ACCOUNT_ID}:role/GitHubActionsRole\""
echo "   gh secret set TERRAFORM_STATE_BUCKET --body \"${S3_BUCKET}\""
echo "   gh secret set TERRAFORM_LOCK_TABLE --body \"${LOCK_TABLE}\""
echo ""
echo "2. Create GitHub environments (Staging, Prod, etc.)"
echo ""
echo "3. Configure branch protection rules"
echo ""
echo "4. Deploy to staging:"
echo "   git push origin develop"
echo ""
echo "5. Monitor deployment:"
echo "   gh run list --branch develop"

# Cleanup
rm -f /tmp/trust-policy.json /tmp/github-actions-policy.json

echo -e "\n${GREEN}Documentation:${NC}"
echo "- Quick Start: QUICKSTART_CI_CD.md"
echo "- Deployment: DEPLOYMENT_GUIDE.md"
echo "- Enterprise Standards: ENTERPRISE_STANDARDS.md"
echo "- Workflows: .github/workflows/README.md"
