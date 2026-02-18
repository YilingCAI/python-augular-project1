# Infrastructure (Terraform) README

AWS infrastructure as code for production deployment.

## Quick Start

```bash
# Validate infrastructure code
make tf-validate ENV=staging

# Plan infrastructure changes
make tf-plan ENV=staging

# Apply infrastructure changes
make tf-apply ENV=staging

# View deployed resources
cd infra && terraform show
```

## Prerequisites

- Terraform 1.5+
- AWS CLI 2.0+
- AWS Account with appropriate permissions
- Bootstrap completed (S3 bucket, DynamoDB, OIDC)

## Project Structure

```
infra/
├── README.md                 # This file
├── main.tf                   # AWS resources
├── variables.tf              # Input variables
├── outputs.tf                # Output values
├── providers.tf              # AWS provider config
├── locals.tf                 # Local computed values
│
├── modules/                  # Reusable modules
│   ├── vpc/                 # VPC, subnets, NAT, IGW
│   ├── rds/                 # PostgreSQL database
│   ├── ecs/                 # ECS cluster and services
│   ├── alb/                 # Application load balancer
│   ├── ecr/                 # Docker registry
│   └── iam/                 # IAM roles and policies
│
├── envs/                     # Environment-specific configs
│   ├── dev.tfvars
│   ├── staging.tfvars
│   └── prod.tfvars
│
└── **/.tfstate/              # (Gitignored) State files
```

## Technologies

- **IaC Framework**: Terraform 1.5
- **Cloud Provider**: AWS
- **State Storage**: S3 + DynamoDB
- **Networking**: VPC, Subnets, Security Groups
- **Compute**: ECS Fargate
- **Database**: RDS PostgreSQL
- **Load Balancing**: Application Load Balancer
- **Container Registry**: ECR

## Architecture Components

### VPC (Virtual Private Cloud)
```
VPC: 10.0.0.0/16
├── Public Subnets (2 AZs)
│   ├── 10.0.101.0/24 (us-east-1a)
│   └── 10.0.102.0/24 (us-east-1b)
│       └── NAT Gateway, ALB
├── Private Subnets (2 AZs)
│   ├── 10.0.1.0/24 (us-east-1a)
│   └── 10.0.2.0/24 (us-east-1b)
│       └── ECS tasks, RDS
└── Internet Gateway, Route Tables, NACLs
```

### ECS Cluster
```
Cluster: myproject-staging
├── Backend Service
│   ├── Task Definition: myproject-backend
│   ├── Image: ECR backend image
│   ├── CPU: 256
│   ├── Memory: 512
│   ├── Port: 8000
│   ├── Desired: 2 tasks
│   └── Auto Scaling: 1-4
├── Frontend Service
│   ├── Task Definition: myproject-frontend
│   ├── Image: ECR frontend image
│   ├── CPU: 256
│   ├── Memory: 512
│   ├── Port: 80
│   ├── Desired: 1 task
│   └── Auto Scaling: 1-2
└── ALB
    └── Target groups for backend & frontend
```

### RDS Database
```
Engine: PostgreSQL 16
Configuration (Staging):
  - Instance: db.t4g.micro
  - Storage: 20 GB
  - Backup: 7 days
  - Multi-AZ: No

Configuration (Production):
  - Instance: db.t4g.small+
  - Storage: 100+ GB
  - Backup: 30 days
  - Multi-AZ: Yes
```

## Configuration

### Environment-Specific Variables

**infra/envs/staging.tfvars:**
```hcl
environment        = "staging"
vpc_cidr           = "10.0.0.0/16"
db_instance_class  = "db.t4g.micro"
ecs_desired_count  = 2
backup_retention   = 7
multi_az           = false
```

**infra/envs/prod.tfvars:**
```hcl
environment        = "prod"
vpc_cidr           = "10.0.0.0/16"
db_instance_class  = "db.t4g.small"
ecs_desired_count  = 3
backup_retention   = 30
multi_az           = true
```

## Terraform Commands

### Initialize
```bash
# One-time setup
cd infra
terraform init

# Uses backend configured in terraform.tf
# State stored in S3, locks in DynamoDB
```

### Validate
```bash
make tf-validate ENV=staging
# Checks syntax without connecting to AWS
```

### Plan
```bash
make tf-plan ENV=staging
# Shows what will be created/changed/destroyed
# Review output carefully before apply
```

### Apply
```bash
make tf-apply ENV=staging
# ⚠️ Requires manual confirmation for production
# Creates/updates/deletes AWS resources
# Exports outputs to /tmp/tf-outputs-staging.json
```

### Destroy
```bash
# ⚠️ DANGEROUS - Destroys all resources
make tf-destroy ENV=staging
# Confirms twice before destroying
```

### State Management
```bash
# List resources
cd infra && terraform state list

# Show specific resource
terraform state show 'aws_db_instance.postgres'

# Remove resource from state (doesn't delete in AWS)
terraform state rm 'aws_instance.example'

# Refresh state from AWS
terraform refresh
```

## Key AWS Resources Created

### Networking
- VPC with public and private subnets
- Internet Gateway
- NAT Gateway (for egress from private subnets)
- Route tables and associations
- Security groups (firewalls)
- Network ACLs

### Compute
- ECS Cluster
- ECS Task Definitions (backend, frontend)
- ECS Services
- Application Load Balancer
- Target Groups
- CloudWatch Log Groups

### Database
- RDS PostgreSQL Instance
- DB Subnet Group
- Parameter Groups
- DB Security Group
- Automated Backups

### Storage
- ECR Repository (backend)
- ECR Repository (frontend)

### Security
- IAM Roles for ECS tasks
- IAM Policies (least privilege)
- Secrets Manager references

## Secrets Management

Secrets are NOT stored in Terraform code. Instead:

1. **Created in AWS Secrets Manager:**
```bash
aws secretsmanager create-secret \
  --name /myproject/staging/db-password \
  --secret-string "password-here"
```

2. **Referenced in Terraform:**
```hcl
data "aws_secretsmanager_secret" "db_password" {
  name = "/myproject/${var.environment}/db-password"
}

locals {
  db_password = jsondecode(
    data.aws_secretsmanager_secret_version.db_password.secret_string
  )
}
```

3. **Injected into ECS:**
```hcl
environment = [
  { name = "DATABASE_PASSWORD", value = local.db_password }
]
```

See [../config/secrets-management.md](../config/secrets-management.md) for details.

## Scaling

### Vertical Scaling (More Resources)
```hcl
# In infra/envs/staging.tfvars
ecs_cpu    = "512"    # was 256
ecs_memory = "1024"   # was 512

# Apply change
make tf-apply ENV=staging
```

### Horizontal Scaling (More Tasks)
```hcl
# In infra/envs/staging.tfvars
ecs_desired_count = 5  # was 2
ecs_max_capacity  = 10 # was 4

# Apply change
make tf-apply ENV=staging
```

### Database Scaling
```hcl
# In infra/envs/prod.tfvars
db_instance_class      = "db.t4g.large"  # was small
db_allocated_storage   = "200"            # was 100
```

## Monitoring

### CloudWatch Logs
```bash
# View ECS logs
aws logs tail /aws/ecs/myproject-staging --follow

# Search for errors
aws logs filter-log-events \
  --log-group-name /aws/ecs/myproject-staging \
  --filter-pattern "ERROR"
```

### CloudWatch Metrics
```bash
# List available metrics
aws cloudwatch list-metrics --namespace AWS/ECS

# Get CPU utilization
aws cloudwatch get-metric-statistics \
  --namespace AWS/ECS \
  --metric-name CPUUtilization \
  --dimensions Name=ClusterName,Value=myproject-staging
```

### CloudWatch Alarms
```bash
# Create CPU alarm
aws cloudwatch put-metric-alarm \
  --alarm-name myproject-high-cpu \
  --metric-name CPUUtilization \
  --namespace AWS/ECS \
  --statistic Average \
  --period 300 \
  --threshold 80
```

## Troubleshooting

### Terraform State Locked
```bash
# DynamoDB lock stuck?
aws dynamodb scan --table-name terraform-locks-staging

# Force unlock (careful!)
terraform force-unlock LOCK_ID
```

### ECS Tasks Not Starting
```bash
# Check task definition
aws ecs describe-task-definition \
  --task-definition myproject-backend

# View stopped tasks
aws ecs list-tasks \
  --cluster myproject-staging \
  --desired-status STOPPED

# Get task details
aws ecs describe-tasks \
  --cluster myproject-staging \
  --tasks <task-arn>
```

### Database Connection Issues
```bash
# Check security group allows traffic
aws ec2 describe-security-groups \
  --group-ids sg-xxxxx

# Test connection from ECS task
aws ecs execute-command \
  --cluster myproject-staging \
  --task <task-arn> \
  --container backend \
  --interactive \
  --command "/bin/bash"
```

### High Costs?
1. Right-size instances (monitor actual usage)
2. Use smaller instances for dev/staging
3. Delete unused resources
4. Use spot instances for non-critical workloads
5. Review AWS Cost Explorer

## Disaster Recovery

### Backup
```bash
# RDS automated backups (configured in Terraform)
# Manual snapshot
aws rds create-db-snapshot \
  --db-instance-identifier myproject-staging \
  --db-snapshot-identifier myproject-staging-snapshot-$(date +%s)
```

### Restore
```bash
# Restore from snapshot
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier myproject-staging-restored \
  --db-snapshot-identifier myproject-staging-snapshot-12345
```

### Recreate Infrastructure
```bash
# Destroy all resources
make tf-destroy ENV=staging

# Recreate from scratch
make tf-apply ENV=staging

# Restore database
# (from snapshot, see above)
```

## Cost Optimization

1. **Use Fargate Spot** (30% cheaper, best for dev/staging)
   ```hcl
   capacity_provider = "FARGATE_SPOT"
   ```

2. **Right-Size Instances**
   - Monitor actual CPU/memory usage
   - Adjust ecs_cpu and ecs_memory accordingly

3. **Use Reserved Capacity** (production baseline)
   - Save ~30-40% with reservations

4. **Archive Logs** (after 30 days)
   ```hcl
   retention_in_days = 30  # Then archive to S3
   ```

5. **Delete Unused Resources**
   ```bash
   # Remove old ECR images
   aws ecr describe-images --repository-name myproject-backend \
     --query 'imageDetails[?imagePushedAt<`2024-01-01`]'
   ```

## Further Reading

- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS VPC Guide](https://docs.aws.amazon.com/vpc/)
- [AWS ECS Guide](https://docs.aws.amazon.com/ecs/)
- [AWS RDS Guide](https://docs.aws.amazon.com/rds/)
- [Terraform Best Practices](https://www.terraform.io/docs/cloud/state/testing.html)

## Related Documentation

- [README.md](../README.md) - Project overview
- [docs/ARCHITECTURE.md](../docs/ARCHITECTURE.md) - System design
- [../backend/README.md](../backend/README.md) - Backend docs
- [../frontend/README.md](../frontend/README.md) - Frontend docs
- [../config/environment-setup.md](../config/environment-setup.md) - Environment config
