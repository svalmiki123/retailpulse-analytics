terraform {
  required_version = ">= 1.0"

  # ── Remote state in S3 ──────────────────────────
  backend "s3" {
    bucket  = "retailpulse-terraform-state-siva-valmiki"
    key     = "snowflake/dev/terraform.tfstate"
    region  = "us-west-2"
    encrypt = true
  }

  required_providers {
    snowflake = {
      source  = "snowflakedb/snowflake"
      version = "~> 2.15"
    }
  }
}

# ─────────────────────────────────────────────────────
# USERADMIN provider — creates roles and users
# This is the DEFAULT provider (no alias)
# ─────────────────────────────────────────────────────
provider "snowflake" {
  organization_name = var.snowflake_organization
  account_name      = var.snowflake_account_name
  user              = var.snowflake_username
  password          = var.snowflake_password
  role              = "USERADMIN"
}

# ─────────────────────────────────────────────────────
# SYSADMIN provider — creates warehouses, databases, schemas
# This is the ALIASED provider
# ─────────────────────────────────────────────────────
provider "snowflake" {
  alias             = "sysadmin"
  organization_name = var.snowflake_organization
  account_name      = var.snowflake_account_name
  user              = var.snowflake_username
  password          = var.snowflake_password
  role              = "SYSADMIN"
}

# ─────────────────────────────────────────────────────
# SECURITYADMIN provider — manages all privilege grants
# ─────────────────────────────────────────────────────
provider "snowflake" {
  alias             = "securityadmin"
  organization_name = var.snowflake_organization
  account_name      = var.snowflake_account_name
  user              = var.snowflake_username
  password          = var.snowflake_password
  role              = "SECURITYADMIN"
}