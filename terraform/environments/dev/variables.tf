variable "snowflake_organization" {
  description = "Snowflake organization name (from CURRENT_ORGANIZATION_NAME())"
  type        = string
  sensitive   = true
}

variable "snowflake_account_name" {
  description = "Snowflake account name (from CURRENT_ACCOUNT_NAME())"
  type        = string
  sensitive   = true
}

variable "snowflake_username" {
  description = "Snowflake admin username for Terraform"
  type        = string
  sensitive   = true
}

variable "snowflake_password" {
  description = "Snowflake admin password for Terraform"
  type        = string
  sensitive   = true
}

variable "environment" {
  description = "Environment name (dev or prod)"
  type        = string
  default     = "dev"
}

variable "dbt_svc_password" {
  description = "Password for the dbt service user"
  type        = string
  sensitive   = true
}

variable "loader_svc_password" {
  description = "Password for the loader service user"
  type        = string
  sensitive   = true
}

variable "reporter_svc_password" {
  description = "Password for the reporter service user"
  type        = string
  sensitive   = true
}