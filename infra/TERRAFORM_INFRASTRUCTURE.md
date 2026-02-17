# Terraform Infrastructure - Complete Deployment Guide

## Overview
Production-ready, modular Terraform infrastructure for deploying FastAPI to AWS ECS Fargate with RDS PostgreSQL, ALB, networking, and comprehensive security.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                          Internet                                │
└────────────────────────────┬────────────────────────────────────┘
                             │ HTTP/HTTPS
                    ┌────────▼────────┐
                    │  ALB (Public)   │
                    │  Port 80/443    │
                    └────────┬────────┘
                             │ Port 8000
                  ┌──────────┼──────────┐
                  │          │          │
            ┌─────▼──┐  ┌─────▼──┐  ┌──▼─────┐
            │  ECS   │  │  ECS   │  │  ECS   │
            │ Task 1 │  │ Task 2 │  │ Task N │
            │ Private│  │Private │  │Private │
            └─────┬──┘  └──┬─────┘  └──┬─────┘
                  │         │          │
                  └─────────┼──────────┘
                            │ PostgreSQL (5432)
                    ┌───────▼────────┐
                    │ RDS PostgreSQL │
                    │   (Private)    │
                    └────────────────┘
```

## Directory Structure

```
infra/
├── main.tf                    # Root module, orchestrates all
├── providers.tf               # AWS provider configuration
├── variables.tf               # Root-level variables
├── outputs.tf                 # Outputs (ALB DNS, ECS cluster name, etc.)
├── backend.tf                 # Optional S3 remote state (commented)
├── terraform.tfvars           # Default values (local development)
├── modules/
│   ├── network/
│   │   ├── main.tf           # VPC, subnets, NAT, IGW, route tables
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── rds/
│   │   ├── main.tf           # RDS PostgreSQL, Secrets Manager
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── ecs/
│   │   ├── main.tf           # ECS cluster, task definition, service, autoscaling
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── alb/
│       ├── main.tf           # ALB, listeners, target groups
│       ├── variables.tf
│       └── outputs.tf
└── envs/
    ├── dev.tfvars             # Development environment
    ├── staging.tfvars         # Staging environment
    └── prod.tfvars            # Production environment
```

## Module Breakdown

### 1. Network Module (`modules/network/`)

**Resources:**
- VPC with configurable CIDR
- Public subnets (for ALB)
- Private subnets (for ECS tasks)
- Database subnets (for RDS, no internet)
- NAT Gateway (for private egress)
- Internet Gateway
- Route tables and associations
- Security groups for ALB, ECS tasks, RDS

**Key Features:**
- Multi-AZ deployment by default
- Proper subnet isolation
- Egress-only database subnets
- Security groups with least privilege

**Outputs:**
```
vpc_id
public_subnet_ids
private_subnet_ids
database_subnet_ids
alb_security_group_id
ecs_tasks_security_group_id
rds_security_group_id
nat_gateway_ip
```

### 2. RDS Module (`modules/rds/`)

**Resources:**
- RDS PostgreSQL instance in private subnets
- DB subnet group
- AWS Secrets Manager for credentials
- KMS key for encryption
- CloudWatch log group
- IAM role for monitoring
- Automated backups and Multi-AZ failover

**Key Features:**
- Encryption at rest (KMS)
- Auto-scaling storage
- Performance insights enabled
- Enhanced monitoring (1-minute granularity)
- 30-day backup retention (configurable per environment)
- Secrets Manager integration for zero hardcoded passwords

**Credential Management:**
```json
{
  "username": "postgres",
  "password": "auto-generated-secure-password",
  "engine": "postgres",
  "host": "db.example.com",
  "port": 5432,
  "dbname": "gamedb"
}
```

**Outputs:**
```
db_endpoint
db_address
db_port
db_name
db_username
secret_arn
secret_name
```

### 3. ALB Module (`modules/alb/`)

**Resources:**
- Application Load Balancer (public)
- Target group (for ECS tasks)
- HTTPS listener (with ACM certificate)
- HTTP listener (redirects to HTTPS)
- S3 bucket for access logs
- Bucket policy for ALB logging

**Key Features:**
- HTTPS/TLS support
- HTTP → HTTPS redirect
- Health checks (path: `/health`, 30s interval)
- Access logging to S3
- Deregistration delay for graceful shutdown

**Health Check Configuration:**
```
Path: /health
Interval: 30 seconds
Timeout: 3 seconds
Healthy threshold: 2
Unhealthy threshold: 3
```

**Outputs:**
```
alb_dns_name
alb_zone_id
target_group_arn
target_group_name
```

### 4. ECS Module (`modules/ecs/`)

**Resources:**
- ECS cluster with Container Insights
- Task definition (Fargate)
- ECS service
- Auto Scaling target and policies (CPU/Memory)
- IAM roles (task execution, task role)
- CloudWatch log group
- CloudWatch alarms for monitoring

**Key Features:**
- Fargate serverless compute
- Auto-scaling based on CPU/Memory
- Container health checks
- Secrets Manager integration for environment variables
- CloudWatch logs
- Zero-downtime deployments

**Task Definition Environment:**
```
DEBUG=false
JWT_ALGORITHM=HS256
JWT_EXPIRE_MINUTES=60
DATABASE_URL=<from Secrets Manager>
JWT_SECRET_KEY=<from Secrets Manager>
```

**Auto-Scaling Policies:**
- CPU Utilization Target: 70% (dev), 60% (prod)
- Memory Utilization Target: 80%
- Scale from min to max capacity

**Outputs:**
```
cluster_name
cluster_id
service_name
service_id
task_definition_arn
log_group_name
```

## Environment-Specific Configurations

### Development (`envs/dev.tfvars`)
```hcl
environment = "dev"
db_instance_class = "db.t3.micro"     # Cost-optimized
desired_count = 1                      # Single task
max_capacity = 3
task_cpu = "256"
task_memory = "512"
multi_az = false                       # Single AZ
debug = true
```

**Estimated Monthly Cost:** $50-80

### Staging (`envs/staging.tfvars`)
```hcl
environment = "staging"
db_instance_class = "db.t3.small"
desired_count = 2                      # HA configuration
max_capacity = 5
task_cpu = "512"
task_memory = "1024"
multi_az = true                        # Multi-AZ
debug = false
```

**Estimated Monthly Cost:** $150-200

### Production (`envs/prod.tfvars`)
```hcl
environment = "prod"
db_instance_class = "db.t3.medium"     # Performance-optimized
desired_count = 3                      # HA + redundancy
max_capacity = 10
task_cpu = "1024"
task_memory = "2048"
multi_az = true                        # Multi-AZ
debug = false
certificate_arn = "arn:aws:acm:..."   # REQUIRED
```

**Estimated Monthly Cost:** $400-600

## Deployment Instructions

### Prerequisites
```bash
# Install Terraform >= 1.5
terraform version

# Configure AWS credentials
aws configure

# Verify ECR repository exists
aws ecr describe-repositories --repository-names mypythonproject1-prod
```

### Step 1: Initialize Terraform
```bash
cd infra
terraform init
```

### Step 2: Validate Configuration
```bash
terraform validate
terraform fmt -recursive .
```

### Step 3: Plan Deployment
```bash
# Development
terraform plan -var-file envs/dev.tfvars -out tfplan

# Or staging
terraform plan -var-file envs/staging.tfvars -out tfplan
```

### Step 4: Review Plan
```bash
terraform show tfplan
```

### Step 5: Apply Configuration
```bash
terraform apply tfplan
```

### Step 6: Capture Outputs
```bash
terraform output -json > outputs.json
```

**Key Outputs:**
```
alb_dns_name = "mypythonproject1-alb-1234567890.us-east-1.elb.amazonaws.com"
ecs_cluster_name = "mypythonproject1-cluster"
ecs_service_name = "mypythonproject1-service"
rds_endpoint = "mypythonproject1-db.c1234567890.us-east-1.rds.amazonaws.com:5432"
cloudwatch_dashboard_url = "https://console.aws.amazon.com/cloudwatch/..."
```

## Updating Infrastructure

### Update ECS Image
```bash
# Set new image tag (e.g., latest git SHA)
terraform apply -var-file envs/prod.tfvars \
  -var image_tag=abc1234567

# ECS service automatically deploys new image
```

### Scale ECS Tasks
```bash
terraform apply -var-file envs/prod.tfvars \
  -var desired_count=5 \
  -var max_capacity=15
```

### Update RDS Instance Class
```bash
# Plan first to review changes
terraform plan -var-file envs/prod.tfvars \
  -var db_instance_class=db.t3.large

# Apply during maintenance window (causes downtime)
terraform apply -var-file envs/prod.tfvars \
  -var db_instance_class=db.t3.large
```

## Security Best Practices Implemented

✅ **Network Security**
- Private subnets for ECS tasks and RDS
- NAT Gateway for secure egress
- Security groups with least privilege
- No wide-open 0.0.0.0/0 except ALB HTTP/HTTPS

✅ **Data Security**
- RDS encryption at rest (KMS)
- Encrypted backups
- Secrets Manager for credentials (no hardcoded values)
- Secrets encrypted with KMS

✅ **Access Control**
- IAM roles with least privilege
- ECS task execution role limited to specific resources
- No root user access to RDS or ECS

✅ **Compliance**
- CloudWatch logs for audit trail
- ALB access logs to S3
- Enhanced RDS monitoring
- VPC Flow Logs capability

## Monitoring & Observability

### CloudWatch Dashboard
Automatic dashboard created with:
- ECS CPU/Memory utilization
- RDS connections and performance
- ALB request count and latency
- Failed task count

**Access:** Check `cloudwatch_dashboard_url` output

### Alarms
Automatically created:
- ECS CPU > 80%
- ECS Memory > 80%
- RDS failover
- ALB target unhealthy

### Logs
- **ECS Logs:** `/ecs/mypythonproject1` (CloudWatch Logs)
- **RDS Logs:** `/aws/rds/mypythonproject1` (PostgreSQL logs)
- **ALB Logs:** `s3://bucket-name/alb-logs/` (S3)

## Cost Optimization

1. **Use Fargate Spot for Dev** - 70% cheaper
   ```hcl
   capacity_providers = ["FARGATE", "FARGATE_SPOT"]
   ```

2. **Right-size instances**
   - Dev: t3.micro (RDS), 256 CPU (ECS)
   - Prod: t3.medium (RDS), 1024 CPU (ECS)

3. **Auto-scale to zero during off-hours**
   ```bash
   # Scale down at night (11 PM) - use EventBridge
   # Scale up in morning (8 AM) - use EventBridge
   ```

4. **Delete unused snapshots**
   ```bash
   aws rds describe-db-snapshots --query 'DBSnapshots[?SnapshotCreateTime<`2024-01-01`]'
   ```

5. **Reserved Capacity for Prod**
   - 12-month RI saves 30-40%

## Disaster Recovery

### RDS Backup & Restore
```bash
# Automated backup (30 days default)
# Restore to specific point in time:
aws rds restore-db-instance-to-point-in-time \
  --source-db-instance-identifier mypythonproject1-db \
  --db-instance-identifier restored-db-instance \
  --restore-time 2024-01-15T14:30:00Z
```

### ECS Task Definition Rollback
```bash
# List previous task definitions
aws ecs list-task-definitions --family-prefix mypythonproject1

# Update service with previous task definition
aws ecs update-service \
  --cluster mypythonproject1-cluster \
  --service mypythonproject1-service \
  --task-definition mypythonproject1-task:2
```

### RDS Multi-AZ Failover
- Automatic failover on primary failure
- 1-2 minute RTO
- No data loss with synchronous replication

## Troubleshooting

### ECS Tasks not starting
```bash
# Check task logs
aws logs tail /ecs/mypythonproject1 --follow

# Check task status
aws ecs describe-tasks \
  --cluster mypythonproject1-cluster \
  --tasks <task-arn>
```

### Cannot connect to RDS
```bash
# Check security group
aws ec2 describe-security-groups \
  --group-ids <rds-security-group-id>

# Test connectivity from ECS task
aws ecs execute-command \
  --cluster mypythonproject1-cluster \
  --task <task-id> \
  --container mypythonproject1 \
  --command "/bin/bash" \
  --interactive
```

### ALB not routing traffic
```bash
# Check target health
aws elbv2 describe-target-health \
  --target-group-arn <tg-arn>

# Check listener rules
aws elbv2 describe-listeners \
  --load-balancer-arn <alb-arn>
```

## Cleanup

### Destroy all resources
```bash
# Plan destruction
terraform plan -destroy -var-file envs/dev.tfvars

# Apply destruction
terraform destroy -var-file envs/dev.tfvars

# Confirm and wait for all resources to be deleted
```

### Keep RDS final snapshot
```bash
# Modify skip_final_snapshot to false
# Terraform will create a final snapshot before deletion
```

## Related Documentation
- [GitHub Actions CI/CD Workflows](./CI_CD_WORKFLOWS.md)
- [Frontend Architecture](./FRONTEND_REFACTORING.md)
- [Backend Improvements](./BACKEND_REFACTORING.md)
