variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-west-2"
}

variable "terraform_state_bucket" {
  description = "S3 bucket for Terraform state"
  type        = string
  default     = "retailpulse-terraform-state-siva-valmiki"
}

variable "data_lake_bucket" {
  description = "S3 bucket for data lake (includes dbt artifacts)"
  type        = string
  default     = "retailpulse-data-lake-siva-valmiki"
}
