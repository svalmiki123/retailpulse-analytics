{{
  config(
    materialized     = 'incremental',
    unique_key       = 'product_id',
    schema           = 'SILVER',
    on_schema_change = 'sync_all_columns',
    tags             = ['silver', 'products']
  )
}}

/*
  Silver: stg_products
  - Casts price columns to FLOAT
  - Converts is_active string to BOOLEAN
  - Calculates margin percentage
  - Incremental on _ingested_at
*/

WITH source AS (

  SELECT * FROM {{ ref('bronze_products') }}

  {% if is_incremental() %}
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
      PARTITION BY product_id
      ORDER BY _ingested_at DESC
    ) AS row_num
  FROM source

),

cleaned AS (

  SELECT
    -- Keys
    product_id                                        AS product_id,

    -- Descriptors
    TRIM(product_name)                                AS product_name,
    INITCAP(TRIM(category))                           AS category,
    INITCAP(TRIM(subcategory))                        AS subcategory,
    TRIM(brand)                                       AS brand,

    -- Prices
    cost_price::FLOAT                                 AS cost_price,
    list_price::FLOAT                                 AS list_price,

    -- Calculated margin
    ROUND(
      (list_price::FLOAT - cost_price::FLOAT)
      / NULLIF(list_price::FLOAT, 0) * 100,
      2
    )                                                 AS margin_pct,

    -- Boolean flag
    CASE
      WHEN LOWER(TRIM(is_active)) = 'true'  THEN TRUE
      WHEN LOWER(TRIM(is_active)) = 'false' THEN FALSE
      ELSE NULL
    END                                               AS is_active,

    -- Dates
    TRY_TO_DATE(created_date, 'YYYY-MM-DD')           AS created_date,

    -- Metadata
    _ingested_at,
    _source_file,

    -- Surrogate key
    {{ dbt_utils.generate_surrogate_key(['product_id']) }}
                                                      AS product_sk

  FROM deduplicated
  WHERE row_num = 1

)

SELECT * FROM cleaned