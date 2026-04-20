{{
  config(
    materialized = 'view',
    schema       = 'BRONZE'
  )
}}

SELECT
  product_id,
  product_name,
  category,
  subcategory,
  brand,
  cost_price,
  list_price,
  is_active,
  created_date,
  _ingested_at,
  _source_file
FROM {{ source('bronze', 'raw_products') }}