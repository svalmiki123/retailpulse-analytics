-- Compile to see generated SQL without running:
-- dbt compile --select analyses/manual_unload.sql
--
-- Run as a one-off operation:
-- dbt run-operation unload_to_s3 --args "{'table_ref': 'DEV_DB.GOLD.FCT_ORDERS', 's3_path': 'fct_orders_manual'}"

{{ unload_to_s3(
    ref('fct_orders'),
    'fct_orders'
) }}