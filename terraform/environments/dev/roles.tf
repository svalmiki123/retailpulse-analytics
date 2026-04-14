# ═══════════════════════════════════════════════════
# CUSTOM ROLES
# Using snowflake_account_role (replaces deprecated snowflake_role)
# ═══════════════════════════════════════════════════

resource "snowflake_account_role" "raw_loader_role" {
  name    = "RAW_LOADER_ROLE"
  comment = "Loads raw data into Bronze layer. Managed by Terraform."
}

resource "snowflake_account_role" "dbt_role" {
  name    = "DBT_ROLE"
  comment = "Runs dbt transformations Bronze to Gold. Managed by Terraform."
}

resource "snowflake_account_role" "analyst_role" {
  name    = "ANALYST_ROLE"
  comment = "Read-only access to Silver and Gold layers. Managed by Terraform."
}

resource "snowflake_account_role" "reporter_role" {
  name    = "REPORTER_ROLE"
  comment = "Read-only access to Gold and Semantic layer. Managed by Terraform."
}

# ═══════════════════════════════════════════════════
# ROLE HIERARCHY
# Grant custom roles up to SYSADMIN
# Using snowflake_grant_account_role (replaces snowflake_role_grants)
# ═══════════════════════════════════════════════════

resource "snowflake_grant_account_role" "raw_loader_to_sysadmin" {
  role_name        = snowflake_account_role.raw_loader_role.name
  parent_role_name = "SYSADMIN"
}

resource "snowflake_grant_account_role" "dbt_to_sysadmin" {
  role_name        = snowflake_account_role.dbt_role.name
  parent_role_name = "SYSADMIN"
}

resource "snowflake_grant_account_role" "analyst_to_sysadmin" {
  role_name        = snowflake_account_role.analyst_role.name
  parent_role_name = "SYSADMIN"
}

resource "snowflake_grant_account_role" "reporter_to_sysadmin" {
  role_name        = snowflake_account_role.reporter_role.name
  parent_role_name = "SYSADMIN"
}

# ═══════════════════════════════════════════════════
# OUTPUTS
# ═══════════════════════════════════════════════════

output "dbt_role_name" {
  value = snowflake_account_role.dbt_role.name
}

output "analyst_role_name" {
  value = snowflake_account_role.analyst_role.name
}

output "reporter_role_name" {
  value = snowflake_account_role.reporter_role.name
}