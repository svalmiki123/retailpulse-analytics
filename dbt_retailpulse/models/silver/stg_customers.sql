{{
  config(
    materialized     = 'incremental',
    unique_key       = 'customer_id',
    schema           = 'SILVER',
    on_schema_change = 'sync_all_columns',
    tags             = ['silver', 'customers']
  )
}}

/*
  Silver: stg_customers
  - Normalizes name fields
  - Casts signup_date to DATE
  - Validates customer_segment values
  - Incremental on _ingested_at
*/

WITH source AS (

  SELECT * FROM {{ ref('bronze_customers') }}

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
      PARTITION BY customer_id
      ORDER BY _ingested_at DESC
    ) AS row_num
  FROM source

),

cleaned AS (

  SELECT
    -- Keys
    customer_id                                       AS customer_id,

    -- Name fields — trim whitespace and normalize case
    TRIM(first_name)                                  AS first_name,
    TRIM(last_name)                                   AS last_name,
    TRIM(first_name) || ' ' || TRIM(last_name)        AS full_name,

    -- Contact
    LOWER(TRIM(email))                                AS email,
    TRIM(phone)                                       AS phone,

    -- Location
    INITCAP(TRIM(city))                               AS city,
    UPPER(TRIM(state))                                AS state,
    UPPER(TRIM(country))                              AS country,

    -- Dates
    TRY_TO_DATE(signup_date, 'YYYY-MM-DD')            AS signup_date,

    -- Segment — normalize to consistent values
    CASE
      WHEN UPPER(TRIM(customer_segment)) = 'PREMIUM'  THEN 'Premium'
      WHEN UPPER(TRIM(customer_segment)) = 'STANDARD' THEN 'Standard'
      ELSE 'Unknown'
    END                                               AS customer_segment,

    -- Metadata
    _ingested_at,
    _source_file,

    -- Surrogate key
    {{ dbt_utils.generate_surrogate_key(['customer_id']) }}
                                                      AS customer_sk

  FROM deduplicated
  WHERE row_num = 1

)

SELECT * FROM cleaned