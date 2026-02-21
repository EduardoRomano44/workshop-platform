# Workshop Platform Infrastructure

Production-grade AWS infrastructure for the workshop platform, featuring multi-account EKS clusters with Fargate, automated CI/CD pipelines, and complete environment isolation.

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Bootstrap Process](#bootstrap-process)
- [GitHub Setup](#github-setup)
- [Local Development](#local-development)
- [CI/CD Pipelines](#cicd-pipelines)
- [Emergency Procedures](#emergency-procedures)
- [Project Structure](#project-structure)

## Overview

This repository contains Terraform infrastructure code for deploying a production-grade Kubernetes platform on AWS. The platform uses:

- **Amazon EKS** with Fargate for serverless container orchestration
- **Amazon ECR** for container image registries with lifecycle policies
- **Multi-account architecture** for complete environment isolation
- **Automated CI/CD** with GitHub Actions
- **Remote state management** with S3 and DynamoDB
- **Environment-specific configurations** for dev, staging, and production

## Architecture

### Multi-Account Setup

Each environment runs in a **separate AWS account** for maximum isolation and security:

```
Development Account (111111111111)
├─ S3 State Bucket
├─ DynamoDB Lock Table
├─ IAM Users (terraform-ci)
└─ EKS Cluster (workshop-eks-dev)

Staging Account (222222222222)
├─ S3 State Bucket
├─ DynamoDB Lock Table
├─ IAM Users (terraform-ci)
└─ EKS Cluster (workshop-eks-stg)

Production Account (333333333333)
├─ S3 State Bucket
├─ DynamoDB Lock Table
├─ IAM Users (terraform-ci)
└─ EKS Cluster (workshop-eks-prd)
```

### Key Features

✅ **Complete isolation** - Separate AWS accounts per environment
✅ **Fargate-only** - No EC2 nodes to manage
✅ **Automated deployments** - GitHub Actions CI/CD
✅ **Cost-optimized** - Dev/staging use single NAT gateway
✅ **Production-ready** - Multi-AZ, full logging, HA configuration

## Prerequisites

Before you begin, ensure you have:

### Required Tools

- **AWS CLI** (v2.x or later) - [Installation Guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- **Terraform** (>= 1.0) - [Installation Guide](https://developer.hashicorp.com/terraform/install)
- **kubectl** - [Installation Guide](https://kubernetes.io/docs/tasks/tools/)
- **Git** - For version control
- **GitHub Account** - With repository access

### AWS Accounts

You'll need access to three AWS accounts:
- Development account
- Staging account
- Production account

**Note**: You can start with a single account and migrate to multi-account later, but separate accounts are **highly recommended** for production.

### AWS Permissions

Your AWS user/role needs permissions to create:
- S3 buckets
- DynamoDB tables
- IAM users, roles, and policies
- VPCs and networking resources
- EKS clusters
- CloudWatch log groups

## Bootstrap Process

The bootstrap process must be completed **once per AWS account** to set up remote state management.

### Step 1: Set Up AWS CLI

Configure AWS CLI for each account:

```bash
# For development account
aws configure --profile workshop-dev
# Enter: Access Key ID, Secret Access Key, Region (eu-west-1), Output format (json)

# For staging account
aws configure --profile workshop-stg

# For production account
aws configure --profile workshop-prd
```

**Alternative** (SSO Login):
```bash
aws sso login --profile workshop-dev
```

### Step 2: Bootstrap Development Account

```bash
# Switch to development account
export AWS_PROFILE=workshop-dev

# Navigate to terraform_init directory
cd terraform_init

# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Expected output: S3 bucket, DynamoDB table, IAM user with policies
# Look for green '+' signs indicating resources to be created

# Apply the configuration with environment variable
terraform apply -var="environment=dev"
# Type 'yes' when prompted
# Creates bucket: workshop-ua-dev-terraform-state

# IMPORTANT: Save the outputs!
terraform output -raw ci_access_key_id > ../dev-access-key.txt
terraform output -raw ci_secret_access_key > ../dev-secret-key.txt

# The outputs contain:
# - S3 bucket name: workshop-ua-dev-terraform-state
# - DynamoDB table name for state locking
# - IAM user credentials for CI/CD
```

### Step 3: Bootstrap Staging Account

```bash
# Switch to staging account
export AWS_PROFILE=workshop-stg

# Run terraform in same directory (it will create resources in new account)
terraform init -reconfigure
terraform plan -var="environment=stg"
terraform apply -var="environment=stg"
# Creates bucket: workshop-ua-stg-terraform-state

# Save outputs
terraform output -raw ci_access_key_id > ../stg-access-key.txt
terraform output -raw ci_secret_access_key > ../stg-secret-key.txt
```

### Step 4: Bootstrap Production Account

```bash
# Switch to production account
export AWS_PROFILE=workshop-prd

# Run terraform
terraform init -reconfigure
terraform plan -var="environment=prd"
terraform apply -var="environment=prd"
# Creates bucket: workshop-ua-prd-terraform-state

# Save outputs
terraform output -raw ci_access_key_id > ../prd-access-key.txt
terraform output -raw ci_secret_access_key > ../prd-secret-key.txt
```

### Step 5: Secure the Credentials

⚠️ **CRITICAL**: The credential files contain sensitive access keys!

```bash
# Add credentials to .gitignore (already done)
# NEVER commit these files to git

# Store credentials securely:
# 1. Add them to GitHub as environment secrets (see next section)
# 2. Delete the local files after setup:
rm ../dev-access-key.txt ../stg-access-key.txt ../prd-access-key.txt
rm ../dev-secret-key.txt ../stg-secret-key.txt ../prd-secret-key.txt
```

## GitHub Setup

Configure GitHub repository for automated CI/CD deployments.

### Step 1: Create GitHub Environments

1. Navigate to your repository on GitHub
2. Go to **Settings** → **Environments**
3. Click **New environment**
4. Create three environments:
   - `dev`
   - `stg`
   - `production`

### Step 2: Configure Environment Secrets

For **each environment**, add the AWS credentials:

#### Development Environment (`dev`)

1. Go to Settings → Environments → **dev**
2. Click **Add secret**
3. Add two secrets:
   - Name: `AWS_ACCESS_KEY_ID`, Value: (from dev-access-key.txt)
   - Name: `AWS_SECRET_ACCESS_KEY`, Value: (from dev-secret-key.txt)

#### Staging Environment (`stg`)

1. Go to Settings → Environments → **stg**
2. Add secrets:
   - Name: `AWS_ACCESS_KEY_ID`, Value: (from stg-access-key.txt)
   - Name: `AWS_SECRET_ACCESS_KEY`, Value: (from stg-secret-key.txt)

#### Production Environment (`production`)

1. Go to Settings → Environments → **production**
2. Add secrets:
   - Name: `AWS_ACCESS_KEY_ID`, Value: (from prd-access-key.txt)
   - Name: `AWS_SECRET_ACCESS_KEY`, Value: (from prd-secret-key.txt)

### Step 3: Configure Production Protection Rules

For the **production** environment:

1. Go to Settings → Environments → **production**
2. Enable **Required reviewers**:
   - Add team members who should approve production deployments
   - Recommended: At least 2 reviewers
3. Enable **Wait timer** (optional):
   - Example: 5 minutes to allow for cancellation
4. Configure **Deployment branches**:
   - Select "Selected branches"
   - Add rule: `main`

### Step 4: Enable GitHub Actions

1. Go to Settings → Actions → General
2. Ensure "Allow all actions and reusable workflows" is selected
3. Under "Workflow permissions":
   - Select "Read and write permissions"
   - Check "Allow GitHub Actions to create and approve pull requests"

## Local Development

### Working with Platform Code

```bash
# Navigate to platform directory
cd platform

# Choose your target environment
export AWS_PROFILE=workshop-dev  # or workshop-stg, workshop-prd

# Initialize Terraform with environment-specific backend
terraform init -backend-config="bucket=workshop-ua-dev-terraform-state"

# Plan changes
terraform plan -var-file="environments/dev.tfvars"

# Apply changes (use with caution!)
terraform apply -var-file="environments/dev.tfvars"
```

### Formatting Code

Always format your code before committing:

```bash
cd platform
terraform fmt -recursive
```

### Switching Between Environments

```bash
# Switch to staging
export AWS_PROFILE=workshop-stg
terraform init -backend-config="bucket=workshop-ua-stg-terraform-state" -reconfigure
terraform plan -var-file="environments/stg.tfvars"

# Switch back to dev
export AWS_PROFILE=workshop-dev
terraform init -backend-config="bucket=workshop-ua-dev-terraform-state" -reconfigure
terraform plan -var-file="environments/dev.tfvars"
```

## ECR Registries

The platform includes an ECR module that creates container image registries for your projects. Each registry is provisioned with a lifecycle policy to manage image retention.

### Configuration

Add project names to the `projects` list in your environment tfvars file:

```hcl
# platform/environments/dev.tfvars
projects = ["spring-petshop", "my-api", "my-frontend"]
```

One ECR repository is created per project name.

### Image Lifecycle Policy

Each repository enforces the following retention rules:

| Tag Pattern  | Retention                          |
|--------------|------------------------------------|
| `*RELEASE`   | Kept indefinitely                  |
| `*SNAPSHOT`  | Only the latest 5 images are kept  |

Images with tags ending in `RELEASE` (e.g., `v1.0.0-RELEASE`) are never expired. Images with tags ending in `SNAPSHOT` (e.g., `v1.0.0-SNAPSHOT`) are automatically cleaned up, keeping only the 5 most recent.

### ECR Outputs

After applying, retrieve the ECR repository URLs and ARNs:

```bash
# Get all ECR repository URLs
terraform output ecr_repository_urls

# Example output:
# {
#   "spring-petshop" = "123456789012.dkr.ecr.eu-west-1.amazonaws.com/spring-petshop"
# }

# Get all ECR repository ARNs
terraform output ecr_repository_arns
```

### Authenticating with ECR

To push images to a registry:

```bash
# Authenticate Docker with ECR
aws ecr get-login-password --region eu-west-1 --profile workshop-dev | \
  docker login --username AWS --password-stdin 123456789012.dkr.ecr.eu-west-1.amazonaws.com

# Tag and push an image
docker tag my-app:latest 123456789012.dkr.ecr.eu-west-1.amazonaws.com/spring-petshop:v1.0.0-RELEASE
docker push 123456789012.dkr.ecr.eu-west-1.amazonaws.com/spring-petshop:v1.0.0-RELEASE
```

For detailed module documentation, see [platform/modules/ecr/README.md](platform/modules/ecr/README.md).

## CI/CD Users (Per-Project)

For each project in the `projects` list, the platform creates a dedicated IAM user with scoped permissions for CI/CD pipelines in separate repositories.

### What Gets Created

Each project gets:

- **IAM User** named `<cluster>-<project>-ci-user` (e.g., `workshop-eks-dev-spring-petshop-ci-user`)
- **Access Keys** for authenticating from CI/CD pipelines
- **IAM Policy** with:
  - ECR push permissions scoped to the project's repository
  - EKS describe permissions for configuring `kubectl`
- **EKS Access Entry** with `AmazonEKSEditPolicy` scoped to a namespace matching the project name
- **Kubernetes Namespace** matching the project name

### CI/CD User Outputs

After applying, retrieve the CI/CD credentials:

```bash
# Get all CI user ARNs
terraform output ci_user_arns

# Get access key IDs
terraform output ci_user_access_key_ids

# Get secret access keys (sensitive)
terraform output -json ci_user_secret_access_keys
```

### Using CI/CD Credentials in a Separate Repository

Configure the access key and secret as secrets in your project's CI/CD pipeline, then:

```bash
# Authenticate with ECR
aws ecr get-login-password --region eu-west-1 | \
  docker login --username AWS --password-stdin <account_id>.dkr.ecr.eu-west-1.amazonaws.com

# Push image
docker push <account_id>.dkr.ecr.eu-west-1.amazonaws.com/spring-petshop:v1.0.0-RELEASE

# Configure kubectl
aws eks update-kubeconfig --region eu-west-1 --name workshop-eks-dev

# Deploy to the project's namespace
kubectl apply -f deployment.yaml -n spring-petshop
```

## CI/CD Pipelines

The repository includes three automated workflows:

### 1. Terraform Plan (Pull Requests)

**Workflow**: `.github/workflows/terraform-plan.yml`

**Triggers**: When a PR is created or updated

**Actions**:
1. ✅ Lint check (runs once)
2. ✅ Plan for dev (parallel)
3. ✅ Plan for stg (parallel)
4. ✅ Plan for prd (parallel)
5. 💬 Post 3 plan outputs as PR comments

**Usage**:
```bash
git checkout -b feature/add-namespace
# Make changes to platform/
git add .
git commit -m "Add new namespace for applications"
git push origin feature/add-namespace
# Create PR → Plans run automatically
```

### 2. Terraform Apply (Main Branch)

**Workflow**: `.github/workflows/terraform-apply.yml`

**Triggers**: Push or merge to `main` branch

**Actions**:
1. ✅ Deploy to dev
2. ⏸️  Wait for success
3. ✅ Deploy to stg
4. ⏸️  Wait for success
5. ✅ Deploy to prd (requires approval)
6. ✅ Final summary

**Sequential Flow**:
```
main branch update
      ↓
  Deploy Dev
      ↓
   Success?
      ↓ Yes
  Deploy Stg
      ↓
   Success?
      ↓ Yes
Approve Prod? (manual)
      ↓ Yes
  Deploy Prd
      ↓
    Done!
```

### 3. Terraform Manual/Emergency

**Workflow**: `.github/workflows/terraform-manual.yml`

**Triggers**: Manual (on-demand)

**Inputs**:
- Environment (dev, stg, prd)
- Action (plan, apply)
- Branch (any branch name)
- Reason (audit trail)

**Usage**:
1. Go to Actions → Terraform Manual/Emergency
2. Click "Run workflow"
3. Select parameters
4. Provide reason for audit
5. Execute

See [Emergency Procedures](#emergency-procedures) for more details.

## Emergency Procedures

### Emergency Hotfix Deployment

For critical production issues that can't wait for the normal PR process:

1. **Create hotfix branch**:
   ```bash
   git checkout -b hotfix/critical-issue-123
   # Make minimal changes to fix the issue
   git commit -m "Fix critical production issue #123"
   git push origin hotfix/critical-issue-123
   ```

2. **Use manual workflow**:
   - Navigate to Actions → Terraform Manual/Emergency
   - Click "Run workflow"
   - Environment: `prd`
   - Action: `apply`
   - Branch: `hotfix/critical-issue-123`
   - Reason: "Emergency fix for production incident #123"

3. **Follow up with PR**:
   ```bash
   # After emergency is resolved, create PR for review
   gh pr create --base main --head hotfix/critical-issue-123
   ```

### Rollback to Previous State

If a deployment causes issues:

1. **Identify previous working commit**:
   ```bash
   git log platform/ --oneline
   ```

2. **Use manual workflow**:
   - Environment: affected environment
   - Action: `apply`
   - Branch: `main` or commit SHA
   - Reason: "Rolling back due to issue #456"

### Testing Changes in Dev

Before creating a PR, test changes in dev:

```bash
# Create feature branch
git checkout -b feature/test-changes

# Make changes
# ...

# Push branch
git push origin feature/test-changes

# Use manual workflow:
# - Environment: dev
# - Action: plan (or apply)
# - Branch: feature/test-changes
# - Reason: "Testing new feature before PR"
```

## Project Structure

```
workshop-platform/
├── .github/
│   ├── workflows/
│   │   ├── terraform-plan.yml              # PR validation
│   │   ├── terraform-apply.yml             # Auto-deployment
│   │   ├── terraform-apply-reusable.yml    # Shared logic
│   │   └── terraform-manual.yml            # Emergency workflow
│   └── CI_CD_SETUP.md                      # Detailed CI/CD docs
│
├── terraform_init/                         # Bootstrap (run once per account)
│   ├── main.tf                            # State bucket, DynamoDB, IAM
│   ├── variables.tf
│   ├── outputs.tf
│   └── README.md
│
├── platform/                               # Main infrastructure
│   ├── environments/                       # Environment configs
│   │   ├── dev.tfvars
│   │   ├── stg.tfvars
│   │   └── prd.tfvars
│   │
│   ├── modules/                           # Reusable modules
│   │   └── ecr/                           # ECR registry module
│   │       ├── main.tf
│   │       ├── variables.tf
│   │       ├── outputs.tf
│   │       └── README.md
│   │
│   ├── backend.tf                         # Remote state config
│   ├── provider.tf                        # Terraform providers
│   ├── vpc.tf                             # VPC and networking
│   ├── security-groups.tf                 # Security groups
│   ├── iam.tf                             # IAM roles and policies
│   ├── eks.tf                             # EKS cluster
│   ├── ecr.tf                             # ECR registries
│   ├── ci_users.tf                        # Per-project CI/CD users
│   ├── fargate.tf                         # Fargate profiles
│   ├── helm-charts.tf                     # AWS LB Controller
│   ├── variables.tf                       # Input variables
│   ├── outputs.tf                         # Output values
│   ├── ENVIRONMENTS.md                    # Environment details
│   └── README.md                          # Platform docs
│
├── CLAUDE.md                              # Project guidelines
└── README.md                              # This file
```

## Important Files

### Configuration Files

- **[platform/environments/](platform/environments/)** - Environment-specific configurations
  - `dev.tfvars` - Development configuration
  - `stg.tfvars` - Staging configuration
  - `prd.tfvars` - Production configuration

### Documentation

- **[platform/README.md](platform/README.md)** - Platform infrastructure details
- **[.github/CI_CD_SETUP.md](.github/CI_CD_SETUP.md)** - CI/CD pipeline guide

## Best Practices

### ✅ Do's

- ✅ Always run `terraform fmt` before committing
- ✅ Test changes in dev before promoting
- ✅ Use PRs for all normal changes
- ✅ Review terraform plans carefully
- ✅ Keep environment configs in sync (where applicable)
- ✅ Use descriptive commit messages
- ✅ Follow up emergency deployments with PRs

### ❌ Don'ts

- ❌ Never commit AWS credentials
- ❌ Don't skip dev/staging when testing
- ❌ Don't manually modify production via console
- ❌ Don't force-push to main
- ❌ Don't share AWS credentials between environments
- ❌ Don't bypass the PR process except for emergencies

## Troubleshooting

### State Lock Errors

If you get "Error acquiring state lock":

```bash
# Check who has the lock
aws dynamodb scan --table-name terraform-state-locks --profile workshop-dev

# If lock is stuck (use with caution):
cd platform
terraform force-unlock <LOCK_ID>
```

### GitHub Actions Failures

1. Check Actions tab for detailed logs
2. Verify environment secrets are set correctly
3. Ensure AWS credentials are valid
4. Check terraform formatting: `terraform fmt -check`

### AWS Credentials Issues

```bash
# Test credentials
aws sts get-caller-identity --profile workshop-dev

# Expected output:
# {
#   "UserId": "...",
#   "Account": "111111111111",
#   "Arn": "..."
# }
```

### Can't Access EKS Cluster

```bash
# Update kubeconfig
aws eks update-kubeconfig --region eu-west-1 --name workshop-eks-dev --profile workshop-dev

# Test access
kubectl get nodes
```

## Getting Help

- **Documentation**: Check [platform/README.md](platform/README.md)
- **CI/CD Issues**: See [.github/CI_CD_SETUP.md](.github/CI_CD_SETUP.md)
- **Terraform Docs**: [terraform.io/docs](https://terraform.io/docs)
- **AWS EKS Guide**: [docs.aws.amazon.com/eks](https://docs.aws.amazon.com/eks/latest/userguide/)

## License

[Your License Here]

## Contributors

[Your Team/Contributors Here]
