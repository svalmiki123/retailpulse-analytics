{{
  config(
    materialized = 'table',
    schema       = 'GOLD',
    tags         = ['gold', 'dimensions']
  )
}}

/*
  dim_products: One row per product with enriched attributes.
  Adds sales performance metrics from Silver orders.
*/

WITH products AS (

  SELECT * FROM {{ ref('stg_products') }}

),

-- Enrich with sales performance from Silver
sales_stats AS (

  SELECT
    product_id,
    COUNT(*)                    AS total_orders,
    SUM(quantity)               AS total_units_sold,
    SUM(net_amount)             AS total_revenue,
    AVG(unit_price)             AS avg_selling_price,
    MIN(order_date)             AS first_sold_date,
    MAX(order_date)             AS last_sold_date
  FROM {{ ref('stg_orders') }}
  GROUP BY product_id

),

final AS (

  SELECT
    -- Surrogate key
    p.product_sk,

    -- Natural key
    p.product_id,

    -- Descriptors
    p.product_name,
    p.category,
    p.subcategory,
    p.brand,

    -- Pricing
    p.cost_price,
    p.list_price,
    p.margin_pct,

    -- Status
    p.is_active,
    p.created_date,

    -- Sales performance
    COALESCE(s.total_orders, 0)       AS total_orders,
    COALESCE(s.total_units_sold, 0)   AS total_units_sold,
    COALESCE(s.total_revenue, 0)      AS total_revenue,
    COALESCE(s.avg_selling_price, 0)  AS avg_selling_price,
    s.first_sold_date,
    s.last_sold_date,

    -- Performance tier
    CASE
      WHEN COALESCE(s.total_revenue, 0) >= 1000  THEN 'Top Seller'
      WHEN COALESCE(s.total_revenue, 0) >= 200   THEN 'Mid Seller'
      WHEN COALESCE(s.total_revenue, 0) > 0      THEN 'Low Seller'
      ELSE 'Never Sold'
    END                               AS performance_tier,

    -- Price tier for segmentation
    CASE
      WHEN p.list_price >= 200  THEN 'Premium'
      WHEN p.list_price >= 50   THEN 'Mid Range'
      ELSE 'Budget'
    END                               AS price_tier,

    -- Metadata
    p._ingested_at

  FROM products p
  LEFT JOIN sales_stats s
    ON p.product_id = s.product_id

)

SELECT * FROM final