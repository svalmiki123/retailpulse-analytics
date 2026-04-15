{{
  config(
    materialized = 'view',
    schema       = 'BRONZE'
  )
}}

/*
  Bronze layer: raw_orders
  - No type casting (that happens in Silver)
  - No business logic
  - Just select all columns and expose via dbt lineage
*/

SELECT
  order_id,
  customer_id,
  product_id,
  order_date,
  ship_date,
  status,
  quantity,
  unit_price,
  discount,
  region,
  _ingested_at,
  _source_file
FROM {{ source('bronze', 'raw_orders') }}