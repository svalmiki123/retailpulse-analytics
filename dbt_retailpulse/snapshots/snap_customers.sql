{% snapshot snap_customers %}

{{
  config(
    target_schema = 'GOLD',
    target_database = 'DEV_DB',
    unique_key    = 'customer_id',
    strategy      = 'check',
    check_cols    = ['customer_segment', 'city', 'state', 'email'],
    invalidate_hard_deletes = True
  )
}}

/*
  SCD Type 2 snapshot of stg_customers.
  Tracks changes to: customer_segment, city, state, email.

  When customer C001 changes from Standard → Premium:
    Row 1: customer_id=C001, segment=Standard, dbt_valid_from=2024-01-01, dbt_valid_to=2024-06-15
    Row 2: customer_id=C001, segment=Premium,  dbt_valid_from=2024-06-15, dbt_valid_to=NULL (current)
*/

SELECT
  customer_id,
  full_name,
  email,
  city,
  state,
  country,
  customer_segment,
  signup_date,
  _ingested_at
FROM {{ ref('stg_customers') }}

{% endsnapshot %}