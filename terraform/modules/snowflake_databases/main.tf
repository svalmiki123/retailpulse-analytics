# ═══════════════════════════════════════════════════
# DATABASES
# ═══════════════════════════════════════════════════
resource "snowflake_database" "this" {
  name    = var.database_name
  comment = var.comment
}

# ═══════════════════════════════════════════════════
# SCHEMAS
# ═══════════════════════════════════════════════════
resource "snowflake_schema" "schemas" {
  for_each = toset(var.schemas)

  database = snowflake_database.this.name
  name     = each.value
  comment  = "Managed by Terraform."
}

# ═══════════════════════════════════════════════════
# GRANTS — USAGE on database + schemas
# ═══════════════════════════════════════════════════
resource "snowflake_grant_privileges_to_account_role" "db_usage" {
  for_each = toset(var.reader_roles)

  account_role_name = each.value
  privileges        = ["USAGE"]
  on_account_object {
    object_type = "DATABASE"
    object_name = snowflake_database.this.name
  }
}

resource "snowflake_grant_privileges_to_account_role" "schema_usage" {
  for_each = {
    for pair in setproduct(var.schemas, var.reader_roles) :
    "${pair[0]}_${pair[1]}" => { schema = pair[0], role = pair[1] }
  }

  account_role_name = each.value.role
  privileges        = ["USAGE"]
  on_schema {
    schema_name = "\"${snowflake_database.this.name}\".\"${each.value.schema}\""
  }

  depends_on = [snowflake_schema.schemas]
}
