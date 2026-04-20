{{
  config(
    materialized = 'view',
    schema       = 'BRONZE'
  )
}}

SELECT
  customer_id,
  first_name,
  last_name,
  email,
  phone,
  city,
  state,
  country,
  signup_date,
  customer_segment,
  _ingested_at,
  _source_file
FROM {{ source('bronze', 'raw_customers') }}