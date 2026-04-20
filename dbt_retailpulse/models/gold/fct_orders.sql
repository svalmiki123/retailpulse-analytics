{{
  config(
    materialized = 'table',
    schema       = 'GOLD',
    tags         = ['gold', 'facts'],
    post_hook    = [
      "{{ audit_log() }}",
      "{{ unload_to_s3(this, 'fct_orders', partition_by='order_date') }}"
    ]
  )
}}

/*
  fct_orders: Central fact table. One row per order.
  Joins Silver orders to all dimensions via surrogate keys.
  Contains all measurable facts (revenue, quantity, discount).
*/

WITH orders AS (

  SELECT * FROM {{ ref('stg_orders') }}

),

customers AS (

  SELECT customer_id, customer_sk, customer_segment, value_tier
  FROM {{ ref('dim_customers') }}

),

products AS (

  SELECT product_id, product_sk, category, subcategory, price_tier
  FROM {{ ref('dim_products') }}

),

dates AS (

  SELECT date_day, date_key, year_num, quarter_name,
         month_num, month_short_name, is_weekend
  FROM {{ ref('dim_date') }}

),

final AS (

  SELECT
    -- Surrogate key for the fact row
    {{ dbt_utils.generate_surrogate_key(['o.order_id']) }}
                                              AS order_sk,

    -- Natural key
    o.order_id,

    -- Foreign keys to dimensions (surrogate keys)
    c.customer_sk,
    p.product_sk,
    d.date_key                                AS order_date_key,

    -- Degenerate dimensions (attributes that don't warrant own dim)
    o.status                                  AS order_status,
    o.region,

    -- Date attributes (denormalized for query convenience)
    o.order_date,
    o.ship_date,
    DATEDIFF(day, o.order_date, o.ship_date)  AS days_to_ship,

    -- Dimension attributes (denormalized for convenience)
    c.customer_segment,
    c.value_tier                              AS customer_value_tier,
    p.category                                AS product_category,
    p.subcategory                             AS product_subcategory,
    p.price_tier                              AS product_price_tier,
    d.year_num                                AS order_year,
    d.quarter_name                            AS order_quarter,
    d.month_short_name                        AS order_month,
    d.is_weekend                              AS ordered_on_weekend,

    -- Measures (the facts)
    o.quantity,
    o.unit_price,
    o.discount,
    o.net_amount,

    -- Derived measures
    CASE
      WHEN o.status = 'RETURNED'
      THEN o.net_amount * -1
      ELSE o.net_amount
    END                                       AS revenue,

    CASE
      WHEN o.status = 'RETURNED' THEN 1
      ELSE 0
    END                                       AS is_returned,

    CASE
      WHEN o.discount > 0 THEN 1
      ELSE 0
    END                                       AS has_discount,

    -- Metadata
    o._ingested_at,
    o._source_file

  FROM orders o
  LEFT JOIN customers c
    ON o.customer_id = c.customer_id
  LEFT JOIN products p
    ON o.product_id  = p.product_id
  LEFT JOIN dates d
    ON o.order_date  = d.date_day

)

SELECT * FROM final