# ─────────────────────────────────────────────
# INGEST_WH — used by Snowpipe and COPY INTO
# ─────────────────────────────────────────────
resource "snowflake_warehouse" "ingest_wh" {
  name                      = "INGEST_WH"
  warehouse_size            = "X-SMALL"
  auto_suspend              = 60
  auto_resume               = true
  initially_suspended       = true
  comment                   = "Used by Snowpipe and COPY INTO. Managed by Terraform."
}

# ─────────────────────────────────────────────
# TRANSFORM_WH — used by dbt runs
# ─────────────────────────────────────────────
resource "snowflake_warehouse" "transform_wh" {
  name                      = "TRANSFORM_WH"
  warehouse_size            = "MEDIUM"
  auto_suspend              = 120
  auto_resume               = true
  initially_suspended       = true
  comment                   = "Used by dbt Core for transformations. Managed by Terraform."
}

# ─────────────────────────────────────────────
# REPORTING_WH — used by Streamlit and analysts
# ─────────────────────────────────────────────
resource "snowflake_warehouse" "reporting_wh" {
  name                      = "REPORTING_WH"
  warehouse_size            = "X-SMALL"
  auto_suspend              = 60
  auto_resume               = true
  initially_suspended       = true
  comment                   = "Used by Streamlit dashboard and Claude AI. Managed by Terraform."
}

# ─────────────────────────────────────────────
# Outputs — printed after terraform apply
# ─────────────────────────────────────────────
output "ingest_wh_name" {
  value = snowflake_warehouse.ingest_wh.name
}

output "transform_wh_name" {
  value = snowflake_warehouse.transform_wh.name
}

output "reporting_wh_name" {
  value = snowflake_warehouse.reporting_wh.name
}