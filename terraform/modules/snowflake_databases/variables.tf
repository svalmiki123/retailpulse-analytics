variable "database_name" {
  description = "Name of the Snowflake database to create."
  type        = string
}

variable "comment" {
  description = "Comment / description for the database."
  type        = string
  default     = "Managed by Terraform."
}

variable "schemas" {
  description = "List of schema names to create inside this database."
  type        = list(string)
  default     = []
}

variable "reader_roles" {
  description = "Account roles to grant USAGE on this database and all its schemas."
  type        = list(string)
  default     = []
}
