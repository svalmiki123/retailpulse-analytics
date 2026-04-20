terraform {
  required_version = ">= 1.0"

  backend "s3" {
    bucket  = "retailpulse-terraform-state-siva-valmiki"
    key     = "aws/github-actions/terraform.tfstate"
    region  = "us-west-2"
    encrypt = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# ─────────────────────────────────────────────────────
# IAM User for GitHub Actions
# ─────────────────────────────────────────────────────
resource "aws_iam_user" "github_actions" {
  name = "github-actions-terraform"
  path = "/ci-cd/"

  tags = {
    Purpose     = "GitHub Actions CI/CD"
    ManagedBy   = "Terraform"
    Environment = "all"
  }
}

# ─────────────────────────────────────────────────────
# IAM Policy for Terraform State Access
# ─────────────────────────────────────────────────────
resource "aws_iam_user_policy" "terraform_state_access" {
  name = "TerraformStateAccess"
  user = aws_iam_user.github_actions.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "TerraformStateList"
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.terraform_state_bucket}"
        ]
      },
      {
        Sid    = "TerraformStateReadWrite"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = [
          "arn:aws:s3:::${var.terraform_state_bucket}/*"
        ]
      }
    ]
  })
}

# ─────────────────────────────────────────────────────
# IAM Policy for dbt Artifacts Access (S3)
# ─────────────────────────────────────────────────────
resource "aws_iam_user_policy" "dbt_artifacts_access" {
  name = "DbtArtifactsAccess"
  user = aws_iam_user.github_actions.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DbtArtifactsList"
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.data_lake_bucket}"
        ]
        Condition = {
          StringLike = {
            "s3:prefix" = ["dbt-artifacts/*", "dbt-docs/*"]
          }
        }
      },
      {
        Sid    = "DbtArtifactsReadWrite"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = [
          "arn:aws:s3:::${var.data_lake_bucket}/dbt-artifacts/*",
          "arn:aws:s3:::${var.data_lake_bucket}/dbt-docs/*"
        ]
      }
    ]
  })
}

# ─────────────────────────────────────────────────────
# Access Keys for GitHub Actions
# ─────────────────────────────────────────────────────
resource "aws_iam_access_key" "github_actions" {
  user = aws_iam_user.github_actions.name
}
