# 🚀 Production-Grade CI/CD Platform

Enterprise-level GitHub Actions workflows for continuous integration and continuous deployment to AWS Fargate.

## 📦 What's Included

### ✅ Workflows
- **CI Pipeline** (`ci.yml`) - Comprehensive testing and security scanning
- **Build & Push** (`build-push-ecr.yml`) - Docker image building and ECR push
- **Terraform Planning** (`terraform-plan.yml`) - Infrastructure planning with validation
- **Terraform Apply** (`terraform-apply.yml`) - Infrastructure deployment
- **Fargate Deployment** (`deploy-fargate.yml`) - ECS service deployment with health checks
- **Staging Deployment** (`deploy-staging.yml`) - Automated staging deployment pipeline
- **Production Deployment** (`deploy-prod.yml`) - Gated production deployment pipeline

### 🔐 Security
- SAST scanning (Bandit, ESLint)
- Secret scanning (GitGuardian)
- Dependency analysis (Snyk)
- Container scanning (Trivy)
- Infrastructure scanning (Checkov, tflint)
- OIDC-based AWS authentication (no secrets!)

### 🛠️ Reusable Actions
- `terraform-validate` - Comprehensive Terraform validation
- `ecs-deploy` - ECS service deployment helper

### 📋 Configuration
- `.trivyignore` - Trivy vulnerability exceptions
- `CODEOWNERS` - Code ownership and review requirements
- `config.json` - Environment-specific configuration

### 📚 Documentation
- `README.md` - Complete workflow documentation
- `.github/workflows/ENTERPRISE_STANDARDS.md` - Enterprise best practices
- `QUICKSTART_CI_CD.md` - Quick start guide
- `DEPLOYMENT_GUIDE.md` - Complete deployment guide
- `SECURITY.md` - Security policy

## 🚀 Quick Start

### 1. Bootstrap AWS (5 minutes)

```bash
chmod +x scripts/bootstrap.sh
./scripts/bootstrap.sh
```

This creates:
- S3 bucket for Terraform state
- DynamoDB table for state locking
- ECR repositories for images
- IAM role for GitHub OIDC

### 2. Configure GitHub Secrets (2 minutes)

```bash
gh secret set AWS_ROLE_TO_ASSUME --body "arn:aws:iam::ACCOUNT:role/GitHubActionsRole"
gh secret set TERRAFORM_STATE_BUCKET --body "terraform-state-ACCOUNT"
gh secret set TERRAFORM_LOCK_TABLE --body "terraform-locks"
```

### 3. Create GitHub Environments (2 minutes)

- `staging` - Auto-deploy
- `prod-approval` - Requires approval for Terraform
- `prod-deployment` - Requires approval for deployment

### 4. Deploy to Staging (1 minute)

```bash
git push origin develop
# → Automatically deploys to staging
```

See [QUICKSTART_CI_CD.md](../QUICKSTART_CI_CD.md) for detailed guide.

## 📊 Workflow Pipeline Overview

```
┌─────────────────────────────────────────────┐
│         Pull Request / Push to Develop      │
└─────────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────┐
│    CI: Security Scanning & Testing          │
│  - SAST (Bandit, ESLint)                    │
│  - Secrets (GitGuardian)                    │
│  - Dependencies (Snyk)                      │
│  - Tests (pytest, Jest)                     │
│  - Coverage reporting                       │
└─────────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────┐
│  Build: Docker Image Creation               │
│  - Multi-stage builds                       │
│  - Layer caching                            │
│  - Container scanning (Trivy)               │
│  - Push to ECR                              │
└─────────────────────────────────────────────┘
                      ↓
         (For Develop Branch)
                      ↓
┌─────────────────────────────────────────────┐
│  Infrastructure: Terraform Plan             │
│  - Format validation                        │
│  - Linting (tflint)                         │
│  - IaC scanning (Checkov)                   │
│  - Plan generation                          │
└─────────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────┐
│  Deploy to Fargate                          │
│  - Pre-deployment validation                │
│  - Task definition update                   │
│  - Service deployment                       │
│  - Health checks                            │
│  - Smoke tests                              │
│  - Automatic rollback on failure            │
└─────────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────┐
│    Staging Environment Live ✅              │
└─────────────────────────────────────────────┘
```

## 🔄 Environment-Specific Flows

### Staging (Automatic)
```
develop push
   ↓
CI ✓
   ↓
Build ✓
   ↓
Terraform plan ✓
   ↓
Terraform apply ✓ (auto)
   ↓
Deploy to Fargate ✓ (auto)
   ↓
✅ Live in staging
```

### Production (Controlled)
```
main push
   ↓
Pre-release checks ✓
   ↓
CI ✓
   ↓
Build ✓
   ↓
Terraform plan ✓
   ↓
🔒 Approval required
   ↓
Terraform apply ✓
   ↓
🔒 Approval required
   ↓
Deploy to Fargate ✓
   ↓
Post-deployment validation ✓
   ↓
✅ Live in production
```

## 📚 Documentation Structure

```
.
├── .github/
│   ├── workflows/
│   │   ├── README.md .......................... This file
│   │   ├── config.json ....................... Environment configuration
│   │   ├── ci.yml ............................ CI pipeline
│   │   ├── build-push-ecr.yml ................ Docker build
│   │   ├── terraform-plan.yml ................ Infra planning
│   │   ├── terraform-apply.yml ............... Infra apply
│   │   ├── deploy-fargate.yml ................ ECS deployment
│   │   ├── deploy-staging.yml ................ Staging orchestration
│   │   └── deploy-prod.yml ................... Production orchestration
│   ├── actions/
│   │   ├── terraform-validate/ ............... Terraform validation action
│   │   ├── ecs-deploy/ ....................... ECS deployment action
│   │   └── aws-assume-role/ .................. AWS auth action
│   └── CODEOWNERS ............................ Code ownership
├── SECURITY.md ............................... Security policy
├── ENTERPRISE_STANDARDS.md ................... Best practices
├── QUICKSTART_CI_CD.md ....................... Quick start
├── DEPLOYMENT_GUIDE.md ....................... Full deployment guide
└── scripts/
    └── bootstrap.sh .......................... AWS setup automation
```

## 🔑 Key Features

### Security First
- No hardcoded credentials
- OIDC-based AWS authentication
- Automated security scanning
- Vulnerability detection
- Secret scanning

### Reliability
- Health checks and monitoring
- Automatic rollback on failure
- Blue-green deployment ready
- Multi-AZ architecture
- Comprehensive logging

### Compliance
- Audit trails
- Change management
- Approval workflows
- Environment parity
- Documentation

### Developer Experience
- Fast feedback loops
- Clear error messages
- Easy rollback
- PR status checks
- Deployment notifications

## 🎯 Common Tasks

### Deploy to Staging
```bash
git push origin develop
# Automatically deploys after ~15 minutes
```

### Deploy to Production
```bash
git push origin main
# Triggers approval workflow
# Review Terraform plan
# Approve deployment
# Deploys after ~20 minutes
```

### Rollback Deployment
```bash
# Automatic rollback on failure
# Manual rollback: See DEPLOYMENT_GUIDE.md
```

### View Logs
```bash
# GitHub Actions
gh run list
gh run view [run-id] --log

# Application logs
aws logs tail /ecs/mypythonproject1 --follow
```

## 🔍 Monitoring & Troubleshooting

### Check Pipeline Status
```bash
# List recent runs
gh run list

# View specific run
gh run view [run-id]

# View detailed logs
gh run view [run-id] --log
```

### Check Application Status
```bash
# ECS services
aws ecs describe-services \
  --cluster mypythonproject1-cluster-prod \
  --services backend-service-prod

# Application logs
aws logs tail /ecs/mypythonproject1 --follow
```

### Troubleshoot Issues
See [DEPLOYMENT_GUIDE.md](../DEPLOYMENT_GUIDE.md#-troubleshooting) for common issues and solutions.

## 🆘 Need Help?

1. **Quick questions** → Check [QUICKSTART_CI_CD.md](../QUICKSTART_CI_CD.md)
2. **Deployment issues** → See [DEPLOYMENT_GUIDE.md](../DEPLOYMENT_GUIDE.md)
3. **Security concerns** → Review [SECURITY.md](../SECURITY.md)
4. **Enterprise standards** → Read [ENTERPRISE_STANDARDS.md](../ENTERPRISE_STANDARDS.md)
5. **Workflow details** → Check individual workflow files

## 📊 Security Scanning Details

### SAST Scanning
- **Bandit** (Python): `bandit -r app/ --severity-level HIGH`
- **ESLint** (JavaScript): `eslint --ext .ts,.js src/`

### Dependency Scanning
- **Snyk**: Scans Python and Node.js dependencies

### Container Scanning
- **Trivy**: Scans Docker images for vulnerabilities

### IaC Scanning
- **Checkov**: Terraform security validation
- **tflint**: Terraform best practices

### Secret Scanning
- **GitGuardian**: Detects secrets in code

## 🚀 Next Steps

1. ✅ Read this README
2. ✅ Run bootstrap script
3. ✅ Configure GitHub secrets
4. ✅ Deploy to staging
5. ✅ Review DEPLOYMENT_GUIDE.md
6. ✅ Deploy to production
7. ✅ Monitor first deployment

## 📞 Support

- **Issues?** Check the documentation
- **Questions?** Review the workflow files
- **Help needed?** Contact your DevOps team

## 📄 License

See LICENSE file in project root.

---

**Last Updated:** February 17, 2026
**Version:** 1.0.0
**Status:** Production Ready ✅
