# ═══════════════════════════════════════════════════
# DATABASES
# ═══════════════════════════════════════════════════

resource "snowflake_database" "raw_db" {
  provider                    = snowflake.sysadmin
  name                        = "RAW_DB"
  comment                     = "Bronze layer — raw ingested data. Managed by Terraform."
  data_retention_time_in_days = 7
  is_transient                = false
}

resource "snowflake_database" "dev_db" {
  provider                    = snowflake.sysadmin
  name                        = "DEV_DB"
  comment                     = "Silver and Gold layers — dbt transformations. Managed by Terraform."
  data_retention_time_in_days = 14
  is_transient                = false
}

resource "snowflake_database" "prod_db" {
  provider                    = snowflake.sysadmin
  name                        = "PROD_DB"
  comment                     = "Production Gold and Semantic layers. Managed by Terraform."
  data_retention_time_in_days = 30
  is_transient                = false
}

# ═══════════════════════════════════════════════════
# SCHEMAS
# ═══════════════════════════════════════════════════

resource "snowflake_schema" "bronze" {
  provider                    = snowflake.sysadmin
  database                    = snowflake_database.raw_db.name
  name                        = "BRONZE"
  comment                     = "Raw ingested tables — append only. Managed by Terraform."
  data_retention_time_in_days = 7
  is_transient                = false
}

resource "snowflake_schema" "silver" {
  provider                    = snowflake.sysadmin
  database                    = snowflake_database.dev_db.name
  name                        = "SILVER"
  comment                     = "Cleaned and conformed models. Managed by Terraform."
  data_retention_time_in_days = 14
  is_transient                = false

}

resource "snowflake_schema" "gold" {
  provider                    = snowflake.sysadmin
  database                    = snowflake_database.dev_db.name
  name                        = "GOLD"
  comment                     = "Fact and dimension tables. Managed by Terraform."
  data_retention_time_in_days = 14
  is_transient                = false

}

resource "snowflake_schema" "semantic" {
  provider                    = snowflake.sysadmin
  database                    = snowflake_database.dev_db.name
  name                        = "SEMANTIC"
  comment                     = "MetricFlow semantic layer. Managed by Terraform."
  data_retention_time_in_days = 14
  is_transient                = false

}

resource "snowflake_schema" "prod_silver" {
  provider                    = snowflake.sysadmin
  database                    = snowflake_database.prod_db.name
  name                        = "SILVER"
  comment                     = "Production Silver layer. Managed by Terraform."
  data_retention_time_in_days = 30
  is_transient                = false

}

resource "snowflake_schema" "prod_gold" {
  provider                    = snowflake.sysadmin
  database                    = snowflake_database.prod_db.name
  name                        = "GOLD"
  comment                     = "Production Gold layer. Managed by Terraform."
  data_retention_time_in_days = 30
  is_transient                = false

}

resource "snowflake_schema" "prod_semantic" {
  provider                    = snowflake.sysadmin
  database                    = snowflake_database.prod_db.name
  name                        = "SEMANTIC"
  comment                     = "Production Semantic layer. Managed by Terraform."
  data_retention_time_in_days = 30
  is_transient                = false

}

# ═══════════════════════════════════════════════════
# DATABASE GRANTS
# USAGE on database — valid for all roles
# ═══════════════════════════════════════════════════

resource "snowflake_grant_privileges_to_account_role" "raw_loader_db_usage" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.raw_loader_role.name
  privileges        = ["USAGE"]
  on_account_object {
    object_type = "DATABASE"
    object_name = snowflake_database.raw_db.name
  }
}

resource "snowflake_grant_privileges_to_account_role" "dbt_raw_db_usage" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.dbt_role.name
  privileges        = ["USAGE"]
  on_account_object {
    object_type = "DATABASE"
    object_name = snowflake_database.raw_db.name
  }
}

resource "snowflake_grant_privileges_to_account_role" "dbt_dev_db_usage" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.dbt_role.name
  privileges        = ["USAGE", "CREATE SCHEMA"]
  on_account_object {
    object_type = "DATABASE"
    object_name = snowflake_database.dev_db.name
  }
}

resource "snowflake_grant_privileges_to_account_role" "analyst_dev_db_usage" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.analyst_role.name
  privileges        = ["USAGE"]
  on_account_object {
    object_type = "DATABASE"
    object_name = snowflake_database.dev_db.name
  }
}

resource "snowflake_grant_privileges_to_account_role" "reporter_dev_db_usage" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.reporter_role.name
  privileges        = ["USAGE"]
  on_account_object {
    object_type = "DATABASE"
    object_name = snowflake_database.dev_db.name
  }
}

resource "snowflake_grant_privileges_to_account_role" "dbt_prod_db_usage" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.dbt_role.name
  privileges        = ["USAGE", "CREATE SCHEMA"]
  on_account_object {
    object_type = "DATABASE"
    object_name = snowflake_database.prod_db.name
  }
}

# ═══════════════════════════════════════════════════
# SCHEMA GRANTS
# USAGE + CREATE privileges on schemas
# ═══════════════════════════════════════════════════

resource "snowflake_grant_privileges_to_account_role" "raw_loader_schema_usage" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.raw_loader_role.name
  privileges        = ["USAGE", "CREATE TABLE", "CREATE STAGE", "CREATE PIPE"]
  on_schema {
    schema_name = "${snowflake_database.raw_db.name}.${snowflake_schema.bronze.name}"
  }
}

resource "snowflake_grant_privileges_to_account_role" "dbt_silver_write" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.dbt_role.name
  privileges        = ["USAGE", "CREATE TABLE", "CREATE VIEW", "CREATE STAGE"]
  on_schema {
    schema_name = "${snowflake_database.dev_db.name}.${snowflake_schema.silver.name}"
  }
}

resource "snowflake_grant_privileges_to_account_role" "dbt_gold_write" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.dbt_role.name
  privileges        = ["USAGE", "CREATE TABLE", "CREATE VIEW", "CREATE STAGE"]
  on_schema {
    schema_name = "${snowflake_database.dev_db.name}.${snowflake_schema.gold.name}"
  }
}

resource "snowflake_grant_privileges_to_account_role" "dbt_semantic_write" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.dbt_role.name
  privileges        = ["USAGE", "CREATE TABLE", "CREATE VIEW"]
  on_schema {
    schema_name = "${snowflake_database.dev_db.name}.${snowflake_schema.semantic.name}"
  }
}

resource "snowflake_grant_privileges_to_account_role" "dbt_prod_silver_write" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.dbt_role.name
  privileges        = ["USAGE", "CREATE TABLE", "CREATE VIEW", "CREATE STAGE"]
  on_schema {
    schema_name = "${snowflake_database.prod_db.name}.${snowflake_schema.prod_silver.name}"
  }
}

resource "snowflake_grant_privileges_to_account_role" "dbt_prod_gold_write" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.dbt_role.name
  privileges        = ["USAGE", "CREATE TABLE", "CREATE VIEW", "CREATE STAGE"]
  on_schema {
    schema_name = "${snowflake_database.prod_db.name}.${snowflake_schema.prod_gold.name}"
  }
}

resource "snowflake_grant_privileges_to_account_role" "dbt_prod_semantic_write" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.dbt_role.name
  privileges        = ["USAGE", "CREATE TABLE", "CREATE VIEW"]
  on_schema {
    schema_name = "${snowflake_database.prod_db.name}.${snowflake_schema.prod_semantic.name}"
  }
}

# ═══════════════════════════════════════════════════
# TABLE GRANTS
# SELECT only on tables — USAGE is NOT valid on tables
# ═══════════════════════════════════════════════════

resource "snowflake_grant_privileges_to_account_role" "dbt_bronze_read" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.dbt_role.name
  privileges        = ["SELECT"]
  on_schema_object {
    all {
      object_type_plural = "TABLES"
      in_schema          = "${snowflake_database.raw_db.name}.${snowflake_schema.bronze.name}"
    }
  }
}

resource "snowflake_grant_privileges_to_account_role" "analyst_silver_read" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.analyst_role.name
  privileges        = ["SELECT"]
  on_schema_object {
    all {
      object_type_plural = "TABLES"
      in_schema          = "${snowflake_database.dev_db.name}.${snowflake_schema.silver.name}"
    }
  }
}

resource "snowflake_grant_privileges_to_account_role" "analyst_gold_read" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.analyst_role.name
  privileges        = ["SELECT"]
  on_schema_object {
    all {
      object_type_plural = "TABLES"
      in_schema          = "${snowflake_database.dev_db.name}.${snowflake_schema.gold.name}"
    }
  }
}

resource "snowflake_grant_privileges_to_account_role" "reporter_gold_read" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.reporter_role.name
  privileges        = ["SELECT"]
  on_schema_object {
    all {
      object_type_plural = "TABLES"
      in_schema          = "${snowflake_database.dev_db.name}.${snowflake_schema.gold.name}"
    }
  }
}

resource "snowflake_grant_privileges_to_account_role" "reporter_semantic_read" {
  provider          = snowflake.securityadmin
  account_role_name = snowflake_account_role.reporter_role.name
  privileges        = ["SELECT"]
  on_schema_object {
    all {
      object_type_plural = "TABLES"
      in_schema          = "${snowflake_database.dev_db.name}.${snowflake_schema.semantic.name}"
    }
  }
}

# ═══════════════════════════════════════════════════
# OUTPUTS
# ═══════════════════════════════════════════════════

output "raw_db_name" { value = snowflake_database.raw_db.name }
output "dev_db_name" { value = snowflake_database.dev_db.name }
output "prod_db_name" { value = snowflake_database.prod_db.name }