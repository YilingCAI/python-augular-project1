# New Team Member Onboarding

Complete guide for new developers joining the team.

## Welcome! 👋

This guide will get you up and running in 30 minutes.

## Prerequisites (15 min)

### 1. System Requirements
- **macOS 12+**, **Ubuntu 20.04+**, or **Windows with WSL2**
- 10+ GB free disk space
- 4+ GB RAM

### 2. Install Required Tools

#### macOS
```bash
# Install Homebrew if not already
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install tools
brew install git python node docker terraform aws-cli

# Start Docker
open --app-path /Applications/Docker.app
```

#### Ubuntu
```bash
sudo apt-get update
sudo apt-get install -y \
  git python3 python3-venv nodejs npm \
  docker.io docker-compose terraform awscli
```

#### Windows (WSL2)
```bash
# In WSL2 terminal
sudo apt-get update
sudo apt-get install -y git python3 python3-venv nodejs npm docker.io terraform awscli

# Install Docker Desktop for Windows with WSL2 backend
# https://docs.docker.com/desktop/install/windows-install/
```

### 3. Verify Installation
```bash
git --version        # git version 2.40+
python3 --version   # Python 3.10+
node --version      # Node 18+
docker --version    # Docker 20.10+
terraform --version # Terraform 1.5+
aws --version       # AWS CLI v2
```

## Project Setup (10 min)

### 1. Clone Repository
```bash
git clone https://github.com/yourteam/mypythonproject1.git
cd mypythonproject1

# Or if you have SSH set up:
git clone git@github.com:yourteam/mypythonproject1.git
cd mypythonproject1
```

### 2. Set Up Local Environment
```bash
# Create local env file
cp config/.env.example .env.local

# Edit with your preferred editor (use dummy values for local dev)
nano .env.local
# or
code .env.local
```

**Minimum required values:**
```env
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/myproject
JWT_SECRET_KEY=local-dev-secret-key
AWS_REGION=us-east-1
```

### 3. Install Dependencies
```bash
make install
# Installs both backend and frontend dependencies
```

### 4. Start Local Development
```bash
# Terminal 1: Start backend
make backend
# Runs on http://localhost:8000

# Terminal 2: Start frontend
make frontend
# Runs on http://localhost:4200

# Terminal 3: Start database (if using Docker)
docker-compose -f deploy/docker-compose.yml up postgres
# Runs on localhost:5432
```

### 5. Verify It Works
```bash
# Open browser tabs:
# - http://localhost:4200 (Frontend)
# - http://localhost:8000/docs (Backend API docs)

# Run tests
make test
```

## Key Concepts (5 min)

### Repository Structure
```
backend/              # FastAPI Python application
frontend/             # Angular TypeScript application
infra/               # AWS infrastructure (Terraform)
scripts/             # DevOps scripts
.github/workflows/   # GitHub Actions CI/CD
config/              # Configuration templates
docs/                # Documentation
tests/               # Integration & E2E tests
Makefile             # Unified CLI
```

### Development Workflow
1. **Create feature branch**: `git checkout -b feature/my-feature`
2. **Make changes** in backend/ or frontend/
3. **Test locally**: `make test`
4. **Format code**: `make format`
5. **Push**: `git push origin feature/my-feature`
6. **Open PR**: Create pull request on GitHub
7. **Get approval**: Team reviews and approves
8. **Merge**: Merge to develop (auto-deploys to staging)

### Environments

| Environment | Purpose | Access |
|-------------|---------|--------|
| **Local** | Development | Your machine |
| **Staging** | Testing | Automatic on develop merge |
| **Production** | Users | Manual approval on main merge |

## Secrets Management

### Important: Never Commit Secrets!

✅ **DO:**
- Store secrets in `.env.local` (gitignored)
- Store CI/CD secrets in GitHub Secrets
- Store runtime secrets in AWS Secrets Manager
- Ask team if you need production credentials

❌ **DON'T:**
- Never commit `.env.local`
- Never commit AWS credentials
- Never hardcode API keys
- Never share credentials in Slack

See [config/secrets-management.md](../config/secrets-management.md) for details.

## First Tasks

### Day 1: Get Familiar
```bash
# Explore the codebase
ls -la backend/
ls -la frontend/

# Read key documentation
cat README.md
cat docs/ARCHITECTURE.md
cat docs/MAKE_REFERENCE.md

# Run the app locally
make dev

# Poke around the API
curl http://localhost:8000/docs  # Swagger UI
curl http://localhost:8000/health

# Explore frontend
# Visit http://localhost:4200 in browser
```

### Day 2: Make a Change
```bash
# Create a branch
git checkout -b onboarding/my-first-change

# Make a small change (typo fix, comment, etc.)
# In backend: add a comment to app/main.py
# In frontend: add a comment to src/app/app.component.ts

# Test it
make test

# Format it
make format

# Commit and push
git add .
git commit -m "docs: add onboarding comment"
git push origin onboarding/my-first-change

# Create PR on GitHub
# (GitHub shows link in terminal)
```

### Day 3: Understand Infrastructure
```bash
# Read infrastructure docs
cat infra/README.md
cat docs/ARCHITECTURE.md

# (Optional) Review Terraform code
cat infra/main.tf
cat infra/variables.tf

# Understand deployment
cat docs/DEPLOYMENT_GUIDE.md

# Look at scripts
ls -la scripts/
cat scripts/setup-env.sh
```

## Common Commands

```bash
# Development
make help              # See all available commands
make dev               # Run everything locally
make test              # Run all tests
make lint              # Check code quality
make format            # Auto-format code

# Before committing
make test
make format
make lint

# Deployment (via GitHub only)
# Don't run manually until you understand the system
make tf-plan ENV=staging  # Plan infrastructure
make deploy ENV=staging   # Deploy to staging
```

## Troubleshooting

### Port Already in Use
```bash
# Backend already running?
lsof -i :8000
kill -9 <PID>

# Frontend already running?
lsof -i :4200
kill -9 <PID>

# Database already running?
lsof -i :5432
kill -9 <PID>
```

### Database Connection Failed
```bash
# Check .env.local
echo $DATABASE_URL

# Start database
docker-compose -f deploy/docker-compose.yml up postgres

# Try connecting
psql $DATABASE_URL -c "SELECT 1"
```

### npm install Fails
```bash
# Clear cache
npm cache clean --force

# Delete node_modules
cd frontend
rm -rf node_modules package-lock.json

# Reinstall
npm install
```

### Python Dependencies Issue
```bash
# Recreate virtual environment
cd backend
rm -rf venv
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -e .
```

## Getting Help

### Questions?
1. Check [docs/TROUBLESHOOTING.md](../docs/TROUBLESHOOTING.md)
2. Search issues on GitHub
3. Ask in #engineering Slack channel
4. Ask your onboarding buddy
5. Schedule pair programming with team

### Documentation
- [README.md](../README.md) - Project overview
- [docs/ARCHITECTURE.md](../docs/ARCHITECTURE.md) - System design
- [docs/MAKE_REFERENCE.md](../docs/MAKE_REFERENCE.md) - All commands
- [backend/README.md](../backend/README.md) - Backend docs
- [frontend/README.md](../frontend/README.md) - Frontend docs
- [infra/README.md](../infra/README.md) - Infrastructure docs

## Checking Your Setup

Run this to verify everything is working:
```bash
# Should show all ✓
make install
make test
make lint
echo "✅ All setup!"
```

## Next Steps

1. ✅ Complete this onboarding
2. ✅ Make your first PR
3. ✅ Get code review approved
4. ✅ Merge to develop
5. ✅ Watch it auto-deploy to staging
6. 📚 Read [docs/ARCHITECTURE.md](../docs/ARCHITECTURE.md)
7. 📚 Read [docs/DEPLOYMENT_GUIDE.md](../docs/DEPLOYMENT_GUIDE.md)
8. ✅ Pair program with senior dev
9. ✅ You're ready to ship!

## Your Onboarding Checklist

- [ ] Installed all tools
- [ ] Cloned repository
- [ ] Created `.env.local`
- [ ] Ran `make install`
- [ ] Started `make dev`
- [ ] Verified http://localhost:4200 works
- [ ] Verified http://localhost:8000/docs works
- [ ] Ran `make test`
- [ ] Read main README.md
- [ ] Read docs/ARCHITECTURE.md
- [ ] Explored backend/ and frontend/ folders
- [ ] Made first change on feature branch
- [ ] Created first PR
- [ ] Got code review approval
- [ ] Merged to develop
- [ ] Watched auto-deploy to staging
- [ ] Celebrated! 🎉

---

**Welcome to the team!** 🚀

If anything is unclear, ask. No question is too basic.
