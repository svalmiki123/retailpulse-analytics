# GitHub Actions IAM User - Terraform Configuration

This Terraform configuration creates a dedicated IAM user for GitHub Actions CI/CD with the necessary permissions.

## What it creates

- **IAM User**: `github-actions-terraform` (path: `/ci-cd/`)
- **Terraform State Access**: Read/write access to the Terraform state S3 bucket
- **dbt Artifacts Access**: Read/write access to dbt artifacts in the data lake bucket
- **Access Keys**: AWS credentials for use in GitHub Actions secrets

## Prerequisites

Before running this configuration, you need AWS credentials with permissions to:
- Create IAM users
- Create IAM policies
- Create access keys

You can use your existing AWS credentials (the ones that created the S3 buckets).

## Initial Setup

This configuration itself requires the Terraform state bucket to exist and have proper permissions. To bootstrap this:

1. **First run**: Comment out the `backend "s3"` block in `main.tf` and run locally with a local backend
2. **After successful apply**: Uncomment the backend configuration and run `terraform init -migrate-state`

Or, temporarily use your admin credentials to initialize this once.

## Usage

```bash
# Navigate to this directory
cd terraform/aws/github-actions

# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply the configuration
terraform apply

# Get the credentials (they are marked as sensitive, so you need to explicitly output them)
terraform output -raw access_key_id
terraform output -raw secret_access_key
```

## Updating GitHub Secrets

After applying this configuration, update your GitHub repository secrets:

```bash
# Get the credentials
export AWS_ACCESS_KEY_ID=$(terraform output -raw access_key_id)
export AWS_SECRET_ACCESS_KEY=$(terraform output -raw secret_access_key)

# Update GitHub secrets using gh CLI
gh secret set AWS_ACCESS_KEY_ID --body "$AWS_ACCESS_KEY_ID"
gh secret set AWS_SECRET_ACCESS_KEY --body "$AWS_SECRET_ACCESS_KEY"
```

Or update them manually in GitHub:
1. Go to: https://github.com/YOUR_USERNAME/retailpulse-analytics/settings/secrets/actions
2. Update `AWS_ACCESS_KEY_ID` with the value from `terraform output -raw access_key_id`
3. Update `AWS_SECRET_ACCESS_KEY` with the value from `terraform output -raw secret_access_key`

## Permissions Granted

### Terraform State Access
- `s3:ListBucket` on `retailpulse-terraform-state-siva-valmiki`
- `s3:GetObject`, `s3:PutObject`, `s3:DeleteObject` on all objects in the bucket

### dbt Artifacts Access
- `s3:ListBucket` on `retailpulse-data-lake-siva-valmiki` (limited to `dbt-artifacts/*` prefix)
- `s3:GetObject`, `s3:PutObject` on `retailpulse-data-lake-siva-valmiki/dbt-artifacts/*`

## Security Notes

- Access keys are stored in Terraform state (encrypted in S3)
- The IAM user follows least-privilege principles with only necessary S3 permissions
- Access keys can be rotated by running `terraform taint aws_iam_access_key.github_actions` and `terraform apply`
- Consider using OIDC instead of long-lived credentials for better security (future enhancement)
