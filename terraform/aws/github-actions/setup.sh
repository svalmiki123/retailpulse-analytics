#!/bin/bash
# Setup script for GitHub Actions IAM user

set -e

echo "🔧 Setting up GitHub Actions IAM user..."
echo ""

# Check if AWS credentials are configured
if ! aws sts get-caller-identity &>/dev/null; then
    echo "❌ AWS credentials not configured or invalid"
    echo "Please configure AWS credentials with permissions to create IAM users"
    echo ""
    echo "Run: aws configure"
    echo "Or set: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_REGION"
    exit 1
fi

echo "✅ AWS credentials found:"
aws sts get-caller-identity
echo ""

# Initialize Terraform
echo "📦 Initializing Terraform..."
terraform init

# Plan
echo ""
echo "📋 Planning changes..."
terraform plan

# Confirm before applying
echo ""
read -p "Do you want to apply these changes? (yes/no): " -r
if [[ ! $REPLY =~ ^[Yy]es$ ]]; then
    echo "Aborted."
    exit 0
fi

# Apply
echo ""
echo "🚀 Applying changes..."
terraform apply -auto-approve

# Get credentials
echo ""
echo "✅ IAM user created successfully!"
echo ""
echo "📝 GitHub Secrets to update:"
echo "================================"
echo ""
echo "AWS_ACCESS_KEY_ID:"
terraform output -raw access_key_id
echo ""
echo ""
echo "AWS_SECRET_ACCESS_KEY:"
terraform output -raw secret_access_key
echo ""
echo ""
echo "AWS_REGION:"
echo "us-west-2"
echo ""
echo "================================"
echo ""
echo "🔐 Update these secrets at:"
echo "https://github.com/$(git config remote.origin.url | sed 's/.*github.com[:/]\(.*\)\.git/\1/')/settings/secrets/actions"
echo ""
echo "Or run the following commands:"
echo ""
echo "gh secret set AWS_ACCESS_KEY_ID --body \"\$(terraform output -raw access_key_id)\""
echo "gh secret set AWS_SECRET_ACCESS_KEY --body \"\$(terraform output -raw secret_access_key)\""
echo "gh secret set AWS_REGION --body \"us-west-2\""
