# Quick Start Guide - Production CI/CD

Get your application deployed to AWS Fargate with production-grade CI/CD in 30 minutes.

## ⚡ 5-Minute Setup

### 1. AWS Setup (5 min)

```bash
# Set your AWS account ID
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export AWS_REGION=us-east-1

# Run setup script
chmod +x scripts/bootstrap.sh
./scripts/bootstrap.sh
```

### 2. GitHub Configuration (5 min)

```bash
# Set your GitHub repo
export GITHUB_ORG="your-org"
export GITHUB_REPO="mypythonproject1"

# Configure secrets
gh secret set AWS_ROLE_TO_ASSUME --body "arn:aws:iam::${AWS_ACCOUNT_ID}:role/GitHubActionsRole"
gh secret set TERRAFORM_STATE_BUCKET --body "terraform-state-${AWS_ACCOUNT_ID}"
gh secret set TERRAFORM_LOCK_TABLE --body "terraform-locks"
gh secret set AWS_REGION --body "${AWS_REGION}"

# Create environments
gh api repos/${GITHUB_ORG}/${GITHUB_REPO}/environments -f name=dev
gh api repos/${GITHUB_ORG}/${GITHUB_REPO}/environments -f name=staging
gh api repos/${GITHUB_ORG}/${GITHUB_REPO}/environments -f name=prod-approval
gh api repos/${GITHUB_ORG}/${GITHUB_REPO}/environments -f name=prod-deployment
```

### 3. Deploy (5 min)

```bash
# Deploy to staging
git checkout develop
git push origin develop

# Monitor deployment
gh run list --branch develop

# Check status
gh run view [run-id]
```

## 📚 Full Workflow

### Staging Deployment (Dev/Testing)

```bash
# 1. Create feature branch
git checkout -b feature/my-feature
git add .
git commit -m "Feature: description"

# 2. Push and create PR to develop
git push origin feature/my-feature
gh pr create --base develop

# 3. Code review and merge
# → GitHub Actions runs CI
# → Builds Docker images
# → Deploys to Fargate (staging)

# 4. Verify deployment
curl https://staging.example.com/api/health
```

### Production Deployment (Live)

```bash
# 1. Create release
git checkout main
git pull origin main
git tag v1.0.0
git push origin main --tags

# 2. GitHub Actions triggers:
#    → Runs full CI pipeline
#    → Plans Terraform
#    → APPROVAL REQUIRED
#    → Applies Terraform
#    → APPROVAL REQUIRED
#    → Deploys to Fargate

# 3. Approve in GitHub UI
gh run approve [run-id]

# 4. Monitor deployment
gh run list --branch main
curl https://api.example.com/api/health

# 5. Verify in CloudWatch
aws logs tail /ecs/mypythonproject1 --follow
```

## 🔍 Monitoring Commands

```bash
# Check deployment status
aws ecs describe-services \
  --cluster mypythonproject1-cluster-prod \
  --services backend-service-prod

# View logs
aws logs tail /ecs/mypythonproject1 --follow

# Check application health
curl https://api.example.com/api/health -v

# List deployments
gh run list --branch main

# View deployment details
gh run view [run-id] --log
```

## 🚨 Quick Rollback

```bash
# Rollback to previous version
aws ecs update-service \
  --cluster mypythonproject1-cluster-prod \
  --service backend-service-prod \
  --task-definition backend-service:$(aws ecs list-task-definitions \
    --family-prefix backend-service \
    --sort DESCENDING \
    --query "taskDefinitionArns[1]" \
    --output text | cut -d: -f2) \
  --force-new-deployment

# Wait for stabilization
aws ecs wait services-stable \
  --cluster mypythonproject1-cluster-prod \
  --services backend-service-prod
```

## 📋 Common Tasks

### Deploy specific version

```bash
gh workflow run deploy-fargate.yml \
  -f environment=staging \
  -f image_tag=v1.0.0
```

### Update infrastructure only

```bash
gh workflow run terraform-apply.yml
```

### View detailed logs

```bash
gh run view [run-id] --log | less
```

### Check test coverage

```bash
# After CI completes
gh run view [ci-run-id] --log | grep -A 10 "coverage"
```

## 🔐 Security Checks

All deployments include:
- ✅ SAST scanning (Bandit, ESLint)
- ✅ Dependency scanning (Snyk)
- ✅ Container scanning (Trivy)
- ✅ Infrastructure scanning (Checkov)
- ✅ Secret scanning (GitGuardian)

Check results:
```bash
# View security scan results
gh run view [ci-run-id] --log | grep -i "security\|vulnerability\|error"
```

## 💡 Pro Tips

1. **Draft PR for early feedback**
   ```bash
   gh pr create --draft
   ```

2. **Skip approval for testing**
   ```bash
   # In GitHub: Push to develop (no approval needed)
   ```

3. **View deployment history**
   ```bash
   aws ecs describe-services \
     --cluster mypythonproject1-cluster-prod \
     --services backend-service-prod \
     --query 'services[0].deployments'
   ```

4. **Monitor in real-time**
   ```bash
   watch -n 5 'aws ecs describe-services \
     --cluster mypythonproject1-cluster-prod \
     --services backend-service-prod \
     --query "services[0].[runningCount,desiredCount,status]"'
   ```

## 📖 Documentation

- **Detailed Workflows**: [.github/workflows/README.md](.github/workflows/README.md)
- **Enterprise Standards**: [ENTERPRISE_STANDARDS.md](ENTERPRISE_STANDARDS.md)
- **Security Policy**: [SECURITY.md](SECURITY.md)
- **Full Deployment Guide**: [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)
- **Infrastructure**: [infra/TERRAFORM_INFRASTRUCTURE.md](infra/TERRAFORM_INFRASTRUCTURE.md)

## ❓ Troubleshooting

**Q: Deployment stuck?**
```bash
# Check logs
gh run view [run-id] --log | tail -50

# Check AWS status
aws ecs describe-services \
  --cluster mypythonproject1-cluster-prod \
  --services backend-service-prod
```

**Q: Image not found?**
```bash
# Verify ECR image
aws ecr list-images \
  --repository-name mypythonproject1/backend \
  --query 'imageIds[?imageTag==`latest`]'
```

**Q: Need to rollback?**
```bash
# See Quick Rollback section above
```

**Q: How to skip approval?**
```bash
# Approve via CLI
gh run approve [run-id]
```

## 🆘 Need Help?

1. Check the detailed documentation
2. Review workflow logs: `gh run view [run-id] --log`
3. Contact DevOps team
4. Check CloudWatch logs: `aws logs tail /ecs/mypythonproject1 --follow`

## 🎯 Next Steps

1. ✅ Complete AWS setup
2. ✅ Configure GitHub secrets
3. ✅ Deploy to staging
4. ✅ Run smoke tests
5. ✅ Deploy to production
6. ✅ Monitor deployment

You're production-ready! 🚀
