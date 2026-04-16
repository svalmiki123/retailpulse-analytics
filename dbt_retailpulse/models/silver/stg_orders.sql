{{
  config(
    materialized  = 'incremental',
    unique_key    = 'order_id',
    schema        = 'SILVER',
    on_schema_change = 'sync_all_columns',
    tags          = ['silver', 'orders']
  )
}}

/*
  Silver: stg_orders
  - Casts all VARCHAR columns to correct types
  - Calculates net_amount business metric
  - Deduplicates using ROW_NUMBER on order_id
  - Incremental: only processes rows newer than last run
*/

WITH source AS (

  SELECT * FROM {{ ref('bronze_orders') }}

  {% if is_incremental() %}
    -- Only pick up rows ingested since the last dbt run
    WHERE _ingested_at > (
      SELECT COALESCE(MAX(_ingested_at), '1900-01-01')
      FROM {{ this }}
    )
  {% endif %}

),

deduplicated AS (

  SELECT
    *,
    ROW_NUMBER() OVER (
      PARTITION BY order_id
      ORDER BY _ingested_at DESC
    ) AS row_num
  FROM source

),

cleaned AS (

  SELECT
    -- Keys
    order_id::INT                               AS order_id,
    customer_id                                 AS customer_id,
    product_id                                  AS product_id,

    -- Dates
    TRY_TO_DATE(order_date, 'YYYY-MM-DD')       AS order_date,
    TRY_TO_DATE(ship_date,  'YYYY-MM-DD')       AS ship_date,

    -- Measures
    quantity::INT                               AS quantity,
    unit_price::FLOAT                           AS unit_price,
    discount::FLOAT                             AS discount,

    -- Calculated
    ROUND(
      (unit_price::FLOAT - discount::FLOAT) * quantity::INT,
      2
    )                                           AS net_amount,

    -- Dimensions
    UPPER(TRIM(status))                         AS status,
    UPPER(TRIM(region))                         AS region,

    -- Metadata
    _ingested_at,
    _source_file,

    -- Surrogate key for stable joins
    {{ dbt_utils.generate_surrogate_key(['order_id']) }}
                                                AS order_sk

  FROM deduplicated
  WHERE row_num = 1   -- keep only the latest version of each order

)

SELECT * FROM cleaned