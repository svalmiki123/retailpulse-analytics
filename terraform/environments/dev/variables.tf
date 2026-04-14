variable "snowflake_account" {
  description = "Snowflake account identifier (e.g. UTHDIQT-NXB55058)"
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