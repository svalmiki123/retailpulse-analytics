resource "snowflake_warehouse" "ingest_wh" {
  provider                            = snowflake.sysadmin
  name                                = "INGEST_WH"
  warehouse_size                      = "X-SMALL"
  auto_suspend                        = 60
  auto_resume                         = true
  initially_suspended                 = true
  enable_query_acceleration           = false
  query_acceleration_max_scale_factor = 0
  comment                             = "Used by Snowpipe and COPY INTO. Managed by Terraform."
}

resource "snowflake_warehouse" "transform_wh" {
  provider                            = snowflake.sysadmin
  name                                = "TRANSFORM_WH"
  warehouse_size                      = "SMALL"
  auto_suspend                        = 120
  auto_resume                         = true
  initially_suspended                 = true
  enable_query_acceleration           = false
  query_acceleration_max_scale_factor = 0
  comment                             = "Used by dbt Core for transformations. Managed by Terraform."
}

resource "snowflake_warehouse" "reporting_wh" {
  provider                            = snowflake.sysadmin
  name                                = "REPORTING_WH"
  warehouse_size                      = "X-SMALL"
  auto_suspend                        = 60
  auto_resume                         = true
  initially_suspended                 = true
  enable_query_acceleration           = false
  query_acceleration_max_scale_factor = 0
  comment                             = "Used by Streamlit dashboard and Claude AI. Managed by Terraform."
}

output "ingest_wh_name" { value = snowflake_warehouse.ingest_wh.name }
output "transform_wh_name" { value = snowflake_warehouse.transform_wh.name }
output "reporting_wh_name" { value = snowflake_warehouse.reporting_wh.name }