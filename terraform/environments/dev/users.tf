# ═══════════════════════════════════════════════════
# SERVICE USERS
# ═══════════════════════════════════════════════════

resource "snowflake_user" "dbt_svc_user" {
  name         = "DBT_SVC_USER"
  login_name   = "DBT_SVC_USER"
  display_name = "dbt Service User"
  email        = "dbt-service@retailpulse.internal"
  comment      = "Service account for dbt Core transformations. Managed by Terraform."

  default_warehouse = snowflake_warehouse.transform_wh.name
  default_role      = snowflake_account_role.dbt_role.name

  password             = var.dbt_svc_password
  must_change_password = false
  disabled             = false
}

resource "snowflake_user" "loader_svc_user" {
  name         = "LOADER_SVC_USER"
  login_name   = "LOADER_SVC_USER"
  display_name = "Loader Service User"
  email        = "loader-service@retailpulse.internal"
  comment      = "Service account for Snowpipe and COPY INTO. Managed by Terraform."

  default_warehouse = snowflake_warehouse.ingest_wh.name
  default_role      = snowflake_account_role.raw_loader_role.name

  password             = var.loader_svc_password
  must_change_password = false
  disabled             = false
}

resource "snowflake_user" "reporter_svc_user" {
  name         = "REPORTER_SVC_USER"
  login_name   = "REPORTER_SVC_USER"
  display_name = "Reporter Service User"
  email        = "reporter-service@retailpulse.internal"
  comment      = "Service account for Streamlit and Claude AI. Managed by Terraform."

  default_warehouse = snowflake_warehouse.reporting_wh.name
  default_role      = snowflake_account_role.reporter_role.name

  password             = var.reporter_svc_password
  must_change_password = false
  disabled             = false
}

# ═══════════════════════════════════════════════════
# ASSIGN ROLES TO USERS
# Using snowflake_grant_account_role with user_name
# (replaces snowflake_role_grants)
# ═══════════════════════════════════════════════════

resource "snowflake_grant_account_role" "dbt_role_to_dbt_user" {
  role_name = snowflake_account_role.dbt_role.name
  user_name = snowflake_user.dbt_svc_user.name
}

resource "snowflake_grant_account_role" "raw_loader_role_to_loader_user" {
  role_name = snowflake_account_role.raw_loader_role.name
  user_name = snowflake_user.loader_svc_user.name
}

resource "snowflake_grant_account_role" "reporter_role_to_reporter_user" {
  role_name = snowflake_account_role.reporter_role.name
  user_name = snowflake_user.reporter_svc_user.name
}

# ═══════════════════════════════════════════════════
# WAREHOUSE ACCESS GRANTS
# Using snowflake_grant_privileges_to_account_role
# (replaces snowflake_warehouse_grant)
# ═══════════════════════════════════════════════════

resource "snowflake_grant_privileges_to_account_role" "transform_wh_to_dbt" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.dbt_role.name
  privileges        = ["USAGE"]
  on_account_object {
    object_type = "WAREHOUSE"
    object_name = snowflake_warehouse.transform_wh.name
  }
}

resource "snowflake_grant_privileges_to_account_role" "ingest_wh_to_loader" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.raw_loader_role.name
  privileges        = ["USAGE"]
  on_account_object {
    object_type = "WAREHOUSE"
    object_name = snowflake_warehouse.ingest_wh.name
  }
}

resource "snowflake_grant_privileges_to_account_role" "reporting_wh_to_reporter" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.reporter_role.name
  privileges        = ["USAGE"]
  on_account_object {
    object_type = "WAREHOUSE"
    object_name = snowflake_warehouse.reporting_wh.name
  }
}

resource "snowflake_grant_privileges_to_account_role" "reporting_wh_to_analyst" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.analyst_role.name
  privileges        = ["USAGE"]
  on_account_object {
    object_type = "WAREHOUSE"
    object_name = snowflake_warehouse.reporting_wh.name
  }
}

# ═══════════════════════════════════════════════════
# OUTPUTS
# ═══════════════════════════════════════════════════

output "dbt_svc_user_name" {
  value = snowflake_user.dbt_svc_user.name
}

output "loader_svc_user_name" {
  value = snowflake_user.loader_svc_user.name
}

output "reporter_svc_user_name" {
  value = snowflake_user.reporter_svc_user.name
}