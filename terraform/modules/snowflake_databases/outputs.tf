output "database_name" {
  description = "Name of the created database."
  value       = snowflake_database.this.name
}

output "schema_names" {
  description = "Names of the created schemas."
  value       = [for s in snowflake_schema.schemas : s.name]
}
