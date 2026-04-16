{{
  config(
    materialized = 'table',
    schema       = 'GOLD',
    tags         = ['gold', 'dimensions'],
    post_hook    = [
      "{{ audit_log() }}",
      "{{ unload_to_s3(this, 'dim_customers') }}"
    ]
  )
}}

/*
  dim_customers: One row per customer with enriched attributes.
  Reads from stg_customers — fully typed and clean.
  Adds derived attributes useful for reporting.
*/

WITH customers AS (

  SELECT * FROM {{ ref('stg_customers') }}

),

-- Calculate order stats from Silver to enrich the dimension
order_stats AS (

  SELECT
    customer_id,
    COUNT(*)                          AS total_orders,
    SUM(net_amount)                   AS lifetime_value,
    MIN(order_date)                   AS first_order_date,
    MAX(order_date)                   AS last_order_date,
    AVG(net_amount)                   AS avg_order_value
  FROM {{ ref('stg_orders') }}
  GROUP BY customer_id

),

final AS (

  SELECT
    -- Surrogate key
    c.customer_sk,

    -- Natural key
    c.customer_id,

    -- Attributes
    c.first_name,
    c.last_name,
    c.full_name,
    c.email,
    c.phone,
    c.city,
    c.state,
    c.country,
    c.signup_date,
    c.customer_segment,

    -- Derived from order history
    COALESCE(o.total_orders, 0)       AS total_orders,
    COALESCE(o.lifetime_value, 0)     AS lifetime_value,
    o.first_order_date,
    o.last_order_date,
    COALESCE(o.avg_order_value, 0)    AS avg_order_value,

    -- Customer tenure in days
    DATEDIFF(day, c.signup_date, CURRENT_DATE()) AS days_since_signup,

    -- Days since last order
    DATEDIFF(day, o.last_order_date, CURRENT_DATE()) AS days_since_last_order,

    -- RFM-style classification
    CASE
      WHEN o.lifetime_value >= 500   THEN 'High Value'
      WHEN o.lifetime_value >= 100   THEN 'Mid Value'
      WHEN o.lifetime_value > 0      THEN 'Low Value'
      ELSE 'No Orders'
    END                               AS value_tier,

    -- Metadata
    c._ingested_at

  FROM customers c
  LEFT JOIN order_stats o
    ON c.customer_id = o.customer_id

)

SELECT * FROM final