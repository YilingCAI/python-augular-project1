# Architecture Overview

Complete system design and component overview for MyPythonProject1.

## System Architecture

```
┌────────────────────────────────────────────────────────────────────────┐
│                            GitHub Repository                          │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │ Code: backend/, frontend/, infra/, scripts/, docs/              │  │
│  │ Config: config/, Makefile, .github/workflows/                   │  │
│  └──────────────────────────────────────────────────────────────────┘  │
└────────────────────┬─────────────────────────────────────────────────────┘
                     │
        ┌────────────┴─────────────┐
        │                          │
   ┌────▼─────────┐        ┌──────▼──────┐
   │ Developer    │        │ Branch      │
   │ Push to      │        │ Push to     │
   │ develop      │        │ main        │
   └────┬─────────┘        └──────┬──────┘
        │                         │
        │                         └─────────────┐
        │                                       │
   ┌────▼─────────────────────┐         ┌──────▼──────────────┐
   │ GitHub Actions:          │         │ GitHub Actions:    │
   │ Staging Pipeline         │         │ Production Pipeline│
   └────┬─────────────────────┘         └──────┬──────────────┘
        │                                      │
        └──────────────┬──────────────────────┘
                       │
        ┌──────────────▼───────────────┐
        │  GitHub Actions Orchestration│
        │  (deploy.yml)                │
        ├──────────────────────────────┤
        │ 1. Validate inputs           │
        │ 2. Run approval gate         │
        │ 3. Terraform plan (if needed)│
        │ 4. Terraform apply (if ok)   │
        │ 5. Docker build & push       │
        │ 6. ECS deploy                │
        └──────────────┬───────────────┘
                       │
        ┌──────────────▼────────────────────┐
        │  AWS Services                     │
        │  ┌──────────────────────────────┐ │
        │  │ IAM & Security               │ │
        │  │ - GitHub OIDC Provider       │ │
        │  │ - Roles & Policies           │ │
        │  └──────────────────────────────┘ │
        │  ┌──────────────────────────────┐ │
        │  │ Storage                      │ │
        │  │ - S3: Terraform state        │ │
        │  │ - DynamoDB: State locks      │ │
        │  │ - ECR: Docker images         │ │
        │  │ - Secrets Manager: App creds │ │
        │  └──────────────────────────────┘ │
        │  ┌──────────────────────────────┐ │
        │  │ Networking                   │ │
        │  │ - VPC: Private/Public subnets│ │
        │  │ - Security Groups: Firewalls │ │
        │  │ - NAT Gateway: Egress        │ │
        │  │ - ALB: Load balancer         │ │
        │  └──────────────────────────────┘ │
        │  ┌──────────────────────────────┐ │
        │  │ Compute                      │ │
        │  │ - ECS Cluster                │ │
        │  │ - Fargate Tasks (Backend)    │ │
        │  │ - Fargate Tasks (Frontend)   │ │
        │  │ - Auto Scaling Group         │ │
        │  └──────────────────────────────┘ │
        │  ┌──────────────────────────────┐ │
        │  │ Database                     │ │
        │  │ - RDS PostgreSQL             │ │
        │  │ - Multi-AZ (prod)            │ │
        │  │ - Automated backups          │ │
        │  │ - Read replicas (optional)   │ │
        │  └──────────────────────────────┘ │
        │  ┌──────────────────────────────┐ │
        │  │ Monitoring & Logging         │ │
        │  │ - CloudWatch Logs (ECS)      │ │
        │  │ - CloudWatch Metrics         │ │
        │  │ - CloudWatch Alarms          │ │
        │  │ - X-Ray (optional tracing)   │ │
        │  └──────────────────────────────┘ │
        └──────────────────────────────────┘
                       │
        ┌──────────────┴───────────────┐
        │                              │
   ┌────▼──────┐              ┌───────▼────┐
   │  Users    │              │ Developers │
   │  Access   │              │  Monitor   │
   │  via      │              │  via       │
   │  ALB/     │              │  CloudWatch│
   │  DNS      │              │  Console   │
   └───────────┘              └────────────┘
```

## Component Breakdown

### 1. GitHub Repository
**Purpose**: Single source of truth for all code and infrastructure

**Contains**:
- Backend source code (FastAPI)
- Frontend source code (Angular)
- Infrastructure code (Terraform)
- Deployment scripts (Bash)
- Documentation and examples
- GitHub Actions workflows

### 2. GitHub Actions (CI/CD)
**Purpose**: Automated testing, building, and deployment

**Workflows**:
- `deploy.yml`: Main orchestration (called by other workflows)
- `deploy-staging.yml`: Triggers on develop branch pushes
- `deploy-prod.yml`: Triggers on main branch pushes (requires approval)

**What Happens**:
1. Code pushed → Workflow triggered
2. Validation checks (inputs, environment)
3. Optional approval gate (production only)
4. Terraform plan → human review → apply
5. Docker build → push to ECR
6. ECS task definition update → deployment
7. Health checks and monitoring

### 3. AWS IAM & Security
**Purpose**: Secure access to AWS resources

**Key Resources**:
- **GitHubActionsRole**: IAM role assumed by GitHub Actions
- **OIDC Provider**: Trust relationship (no API keys needed)
- **Policies**: Least-privilege access for each service

**Why OIDC?**
- No hardcoded AWS credentials
- Credentials automatically rotated
- Audit trail in CloudTrail
- Industry standard approach

### 4. AWS Storage (S3 & DynamoDB)
**Purpose**: Store Terraform state and infrastructure locks

**S3 Bucket** (`myproject-tf-state-staging`):
- Stores Terraform state files (.tfstate)
- Versioning enabled (recover previous states)
- Encryption enabled (SSE-S3)
- Private access only

**DynamoDB Table** (`terraform-locks-staging`):
- Prevents simultaneous Terraform applies
- Avoids conflicts and corruption
- Auto-cleanup after 5 minutes

### 5. AWS ECR (Elastic Container Registry)
**Purpose**: Store Docker images

**Registries** (per environment):
- `123456789012.dkr.ecr.us-east-1.amazonaws.com/myproject-backend:staging`
- `123456789012.dkr.ecr.us-east-1.amazonaws.com/myproject-frontend:staging`

**Image Management**:
- Images tagged with build number or version
- Lifecycle policies delete old images
- Vulnerability scanning with Trivy

### 6. AWS Secrets Manager
**Purpose**: Secure secret storage

**Stored Secrets**:
- `/myproject/staging/db-password`
- `/myproject/staging/jwt-secret`
- `/myproject/staging/api-keys`

**Access Pattern**:
- Terraform reads secrets
- Passes to ECS via task definition environment
- Application reads from environment at runtime

### 7. AWS VPC (Virtual Private Cloud)
**Purpose**: Isolated network for all resources

**Architecture**:
- **VPC CIDR**: 10.0.0.0/16
- **Public Subnets** (2 AZs):
  - 10.0.101.0/24 (us-east-1a)
  - 10.0.102.0/24 (us-east-1b)
  - Contains: NAT Gateway, ALB
- **Private Subnets** (2 AZs):
  - 10.0.1.0/24 (us-east-1a)
  - 10.0.2.0/24 (us-east-1b)
  - Contains: ECS tasks, RDS database

**Network Flow**:
```
Internet → ALB (public) → ECS tasks (private)
ECS tasks → NAT Gateway → Internet (for package downloads)
ECS tasks → RDS (private, same VPC)
```

### 8. AWS ALB (Application Load Balancer)
**Purpose**: Distribute incoming traffic

**Features**:
- Public IP for accepting traffic
- Health checks on backend tasks
- Path-based routing (backend/frontend)
- SSL/TLS termination (optional)

**Listeners**:
- Port 80 (HTTP) → Port 8000 (backend)
- Port 80 (HTTP) → Port 80 (frontend)

### 9. AWS ECS (Elastic Container Service)
**Purpose**: Run containerized applications

**Cluster**: `myproject-staging`
- **Backend Service**:
  - Container: FastAPI app
  - Port: 8000
  - Desired Tasks: 2
  - Task Size: 256 CPU, 512 memory
- **Frontend Service**:
  - Container: Angular app (Nginx)
  - Port: 80
  - Desired Tasks: 1 (can scale)
  - Task Size: 256 CPU, 512 memory

**Task Definition**:
- Pulls image from ECR
- Injects environment variables (from Secrets Manager)
- Configures logging to CloudWatch
- Sets resource limits (CPU, memory)

### 10. AWS RDS (Relational Database Service)
**Purpose**: Managed PostgreSQL database

**Configuration** (staging):
- Engine: PostgreSQL 16.1
- Instance: db.t4g.micro
- Storage: 20 GB (gp2)
- Backup: 7 days
- Multi-AZ: Disabled

**Configuration** (production):
- Engine: PostgreSQL 16.1
- Instance: db.t4g.small or larger
- Storage: 100+ GB (gp3)
- Backup: 30 days
- Multi-AZ: Enabled (high availability)

**Access**:
- Only accessible from VPC (private subnet)
- Security group restricts to ECS tasks only
- Encrypted at rest (KMS)

### 11. AWS CloudWatch
**Purpose**: Monitoring, logging, and alerting

**Logs** (`/aws/ecs/myproject-staging`):
- All ECS task logs centralized
- Searchable and filterable
- 7-14 day retention

**Metrics**:
- ECS CPU utilization
- ECS memory utilization
- ALB target health
- RDS connections

**Alarms** (optional):
- Alert when CPU > 80%
- Alert when memory > 90%
- Alert when healthy targets = 0

## Data Flow Examples

### User Makes a Request
```
User Browser
    ↓ (https://myapp.example.com)
    ↓
ALB (public, 0.0.0.0:443)
    ↓
    ├→ Frontend task (Angular Nginx) :80
    │   ↓
    │   Serves HTML/CSS/JS
    │   ↓
    │   Browser makes API call (http://backend:8000/api/...)
    │
    └→ Backend task (FastAPI) :8000
        ↓
        Authentication (JWT from Secrets Manager)
        ↓
        RDS Database (PostgreSQL in private subnet)
        ↓
        Returns JSON response
```

### Deployment Process
```
Developer pushes code
    ↓
GitHub webhook triggers workflow
    ↓
GitHub Actions:
  1. Checkout code
  2. Assume AWS role (OIDC)
  3. Run Terraform plan (DynamoDB locks state)
  4. Human review
  5. Terraform apply (creates/updates AWS resources)
  6. Build Docker images (with Trivy scanning)
  7. Push to ECR
  8. Update ECS task definition
  9. Update ECS service
  10. Wait for tasks to become healthy
  11. Run smoke tests
  12. Report success/failure
    ↓
Users see new version live
```

## Environment Differences

| Component | Dev | Staging | Production |
|-----------|-----|---------|------------|
| ECS Instance | t4g.micro | t4g.micro | t4g.small+ |
| Desired Tasks | 1 | 2 | 3+ |
| Multi-AZ | No | No | Yes |
| RDS Instance | local | db.t4g.micro | db.t4g.small+ |
| Backup Retention | None | 7 days | 30 days |
| State Locking | N/A | DynamoDB | DynamoDB |
| Approval Gate | N/A | Optional | Required |
| HTTPS | No | No | Yes |
| Auto Scaling | No | No | Yes (1-10) |

## Security Layers

### Layer 1: Repository
- Branch protection rules
- PR approval requirements
- Code review process

### Layer 2: CI/CD
- GitHub Actions secrets (encrypted)
- OIDC authentication (no hardcoded creds)
- Artifact retention policies
- Deployment approval gates

### Layer 3: AWS
- IAM roles and policies
- Security groups (firewalls)
- Private subnets (not accessible from internet)
- Encrypted state storage
- Secrets Manager encryption

### Layer 4: Application
- Authentication (JWT tokens)
- HTTPS/TLS (in production)
- Environment variable injection
- SQL parameter escaping

## Scaling Considerations

### Vertical Scaling (same instance, more resources)
```bash
# Edit infra/envs/staging.tfvars
ecs_cpu    = "512"      # was 256
ecs_memory = "1024"     # was 512

make tf-apply ENV=staging
```

### Horizontal Scaling (more instances)
```bash
# Edit infra/envs/staging.tfvars
ecs_desired_count = 5   # was 2
ecs_max_capacity  = 20  # was 4

make tf-apply ENV=staging
```

### Auto Scaling (based on metrics)
- CloudWatch metrics trigger scaling policies
- Min: 2, Max: 10 (example)
- Scale out when CPU > 70%
- Scale in when CPU < 30%

## Cost Optimization

1. **Use spot instances** (Fargate Spot) for non-critical workloads
2. **Right-size instances** (monitor actual usage)
3. **Use reserved capacity** for production baseline
4. **Archive logs** to S3 after 90 days
5. **Delete old ECR images** via lifecycle policies
6. **Use Aurora** instead of RDS for higher workloads
