# CI/CD Workflows Documentation

Production-ready, enterprise-grade CI/CD pipeline for multi-environment deployment to AWS Fargate with comprehensive security scanning and governance.

## 📋 Workflow Overview

### 1. **CI Workflow** (`ci.yml`)
Runs on every push and pull request. Performs comprehensive testing, linting, and security scanning.

**Stages:**
- Security Scanning (Trivy, Checkov, GitGuardian)
- Backend Testing (Python, pytest with coverage)
- Frontend Testing (Node.js, Jest with coverage)
- Terraform Validation
- Dependency Analysis (Snyk)
- Docker Image Build & Scan
- Coverage Reports to Codecov

**Triggers:**
```yaml
- All branches on push
- PRs to main, develop, staging
```

### 2. **Build & Push to ECR** (`build-push-ecr.yml`)
Builds and pushes Docker images to AWS ECR after successful CI.

**Features:**
- Multi-stage Docker builds with layer caching
- Trivy vulnerability scanning
- ECR login and push
- Build artifact reporting

**Triggers:**
```yaml
- After successful CI workflow
- On main, develop, staging branches
```

### 3. **Terraform Plan** (`terraform-plan.yml`)
Validates and plans Terraform changes for all environments.

**Stages:**
- Terraform format validation
- Terraform init and validate
- tflint security linting
- Terraform plan generation
- Checkov IaC scanning
- PR comments with plan summary

**Triggers:**
```yaml
- Pull requests affecting infra/**
- Pushes to main/staging on infra changes
```

### 4. **Terraform Apply** (`terraform-apply.yml`)
Applies approved Terraform changes to target environment.

**Features:**
- Workflow dispatch for manual triggering
- Environment selection (dev/staging/prod)
- State locking with DynamoDB
- Output artifact generation
- Deployment status tracking

**Triggers:**
```yaml
- Manual workflow dispatch
- Environment selection required
```

### 5. **Deploy to Fargate** (`deploy-fargate.yml`)
Handles ECS Fargate deployment with health checks and rollback.

**Stages:**
- Pre-deployment validation
- ECR image verification
- ECS cluster health check
- Task definition updates
- Service deployment
- Smoke tests
- Automatic rollback on failure

**Features:**
- Blue-green deployment ready
- Health check verification
- Automatic rollback capability
- Deployment records
- Post-deployment validation

**Triggers:**
```yaml
- Manual workflow dispatch
- After successful ECR build (develop/main)
```

### 6. **Deploy to Staging** (`deploy-staging.yml`)
Orchestrates staging deployment.

**Workflow:**
1. Validates CI completion
2. Plans Terraform changes
3. Applies Terraform
4. Deploys to Fargate

**Triggers:**
```yaml
- Push to develop branch
- Manual workflow dispatch
```

### 7. **Deploy to Production** (`deploy-prod.yml`)
Orchestrates production deployment with approval gates.

**Workflow:**
1. Pre-release checks
2. Validates CI completion
3. Plans Terraform changes
4. **Manual Approval Gate** for Terraform
5. Applies Terraform
6. **Manual Approval Gate** for Deployment
7. Deploys to Fargate
8. Post-deployment validation
9. Creates GitHub release

**Features:**
- Two-step approval process
- Pre-release commit validation
- Extended health checks
- GitHub release creation
- Deployment notification

**Triggers:**
```yaml
- Push to main branch
- Manual workflow dispatch
```

## 🔐 Security Features

### Static Analysis
- **SAST**: Bandit (Python), ESLint (JavaScript)
- **Secret Scanning**: GitGuardian
- **Dependency Scanning**: Snyk
- **Container Scanning**: Trivy

### Infrastructure as Code
- **Checkov**: Terraform security validation
- **tflint**: Terraform linting
- **Formatting**: Automated fmt validation

### Access Control
- AWS IAM role assumption via OIDC (no credentials in secrets)
- GitHub branch protection rules
- Manual approval gates for production
- Least privilege IAM policies

### Secret Management
- All secrets stored in GitHub Secrets
- Never logged or exposed in workflow output
- Environment-specific secrets isolation
- AWS credentials rotated automatically

## 📊 Environment Setup

### Prerequisites

1. **AWS Resources**
   ```bash
   # S3 bucket for Terraform state
   aws s3api create-bucket --bucket terraform-state-prod
   
   # DynamoDB table for state locking
   aws dynamodb create-table \
     --table-name terraform-locks \
     --attribute-definitions AttributeName=LockID,AttributeType=S \
     --key-schema AttributeName=LockID,KeyType=HASH \
     --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5
   ```

2. **GitHub Secrets** (Settings > Secrets)
   ```
   AWS_ROLE_TO_ASSUME          # IAM role ARN for OIDC
   TERRAFORM_STATE_BUCKET      # S3 bucket name
   TERRAFORM_LOCK_TABLE        # DynamoDB table name
   GITGUARDIAN_API_KEY         # GitGuardian API key (optional)
   SNYK_TOKEN                  # Snyk API token (optional)
   ```

3. **GitHub Environments** (Settings > Environments)
   - `staging`: Auto-deploy, no approval required
   - `prod-approval`: Manual approval for Terraform
   - `prod-deployment`: Manual approval for deployment

### AWS IAM Setup

Create an IAM role for OIDC federation:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:ORG/REPO:*"
        }
      }
    }
  ]
}
```

## 🚀 Usage

### Staging Deployment (Automatic)
```bash
# Push to develop branch
git push origin develop
# → Automatically triggers CI → Build → Terraform → Deploy
```

### Staging Deployment (Manual)
```bash
# GitHub UI → Actions → Deploy to Staging → Run workflow
# Select branch and options
```

### Production Deployment
```bash
# Push to main branch (or with release tag)
git push origin main
# → Runs full pipeline with approval gates
# → Requires approval for Terraform changes
# → Requires approval for Fargate deployment
```

### Manual Fargate Deployment
```bash
# GitHub UI → Actions → Deploy to Fargate
# Select environment and image tag
```

### Manual Terraform Apply
```bash
# GitHub UI → Actions → Terraform Apply
# Select environment
```

## 📝 Customization

### Adding New Environments

1. Update `infra/envs/` with new `.tfvars` file
2. Add environment to GitHub Environments
3. Modify workflow inputs to include new environment

### Modifying Health Checks

Edit `deploy-fargate.yml` smoke tests section:
```yaml
- name: Run smoke tests
  run: |
    # Customize health check endpoints and logic
```

### Adjusting Approval Workflows

Edit environment settings in GitHub UI or use:
```yaml
environment:
  name: prod-approval
  # Add required reviewers
```

## 🔧 Troubleshooting

### Workflow Failures

**CI Failures:**
- Check test logs: Actions > CI > Backend/Frontend Tests
- Review security scan results
- Check code formatting: `terraform fmt -recursive infra/`

**Terraform Plan Failures:**
- Verify AWS credentials and permissions
- Check S3 bucket and DynamoDB table access
- Review Terraform state lock issues

**ECR Push Failures:**
- Verify AWS ECR login credentials
- Check ECR repository exists
- Review image size and tags

**Fargate Deployment Failures:**
- Check ECS cluster status
- Review task definition compatibility
- Verify ALB and target group configuration
- Check security groups and network settings

### Common Issues

**"Cannot find module"**: Ensure Terraform modules are properly sourced and initialized

**"Image not found in ECR"**: Verify build completed and image was pushed

**"Service is not stable"**: Check CloudWatch logs for container errors

**"Cannot assume role"**: Verify OIDC provider configuration and role trust relationship

## 📊 Monitoring

### CloudWatch Integration
- ECS task logs in `/ecs/mypythonproject1`
- ALB access logs in S3
- CloudWatch Container Insights enabled

### GitHub Integration
- Deployment status visible on commits
- PR status checks enforce policies
- Environment deployments tracked

### Alerts
- Failed workflow notifications
- Manual approval waiting indicators
- Deployment status updates

## 🔄 Best Practices

1. **Always use branches**: Never push directly to main/develop
2. **Require reviews**: Use CODEOWNERS for governance
3. **Test locally**: Run `terraform plan` before pushing
4. **Monitor deployments**: Check CloudWatch logs post-deployment
5. **Review security scans**: Address all CRITICAL/HIGH findings
6. **Rotate secrets**: Update AWS credentials regularly
7. **Version Terraform**: Keep TF_VERSION consistent
8. **Document changes**: Include deployment notes in PRs

## 📚 References

- [AWS Fargate Documentation](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/launch_types.html)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [OWASP Security Practices](https://owasp.org/)
- [AWS Security Best Practices](https://aws.amazon.com/architecture/security-identity-compliance/)

## 📞 Support

For issues or questions:
1. Check this documentation
2. Review workflow logs in GitHub Actions
3. Consult AWS CloudWatch logs
4. Contact your DevOps team
