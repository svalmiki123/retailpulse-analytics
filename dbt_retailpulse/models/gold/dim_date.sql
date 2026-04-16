{{
  config(
    materialized = 'table',
    schema       = 'GOLD',
    tags         = ['gold', 'dimensions']
  )
}}

/*
  dim_date: Date spine from 2023-01-01 to 2027-12-31
  Generated entirely in SQL — no source table needed.
  One row per calendar date with all useful attributes pre-calculated.
*/

WITH date_spine AS (

  SELECT
    DATEADD(day, SEQ4(), '2023-01-01'::DATE) AS date_day
  FROM TABLE(GENERATOR(ROWCOUNT => 1827))  -- 5 years of dates

),

final AS (

  SELECT
    -- Primary key
    date_day                                          AS date_day,

    -- Surrogate key as integer YYYYMMDD — fast for joining
    TO_NUMBER(TO_CHAR(date_day, 'YYYYMMDD'))          AS date_key,

    -- Year
    YEAR(date_day)                                    AS year_num,

    -- Quarter
    QUARTER(date_day)                                 AS quarter_num,
    'Q' || QUARTER(date_day)                          AS quarter_name,
    YEAR(date_day) || '-Q' || QUARTER(date_day)       AS year_quarter,

    -- Month
    MONTH(date_day)                                   AS month_num,
    TO_CHAR(date_day, 'Mon')                          AS month_short_name,
    TO_CHAR(date_day, 'MMMM')                         AS month_long_name,
    TO_CHAR(date_day, 'YYYY-MM')                      AS year_month,

    -- Week
    WEEKOFYEAR(date_day)                              AS week_of_year,
    DATE_TRUNC('week', date_day)                      AS week_start_date,

    -- Day
    DAY(date_day)                                     AS day_of_month,
    DAYOFWEEK(date_day)                               AS day_of_week_num,
    DAYOFYEAR(date_day)                               AS day_of_year,
    TO_CHAR(date_day, 'Day')                          AS day_name,
    TO_CHAR(date_day, 'Dy')                           AS day_short_name,

    -- Flags
    CASE WHEN DAYOFWEEK(date_day) IN (0, 6)
         THEN TRUE ELSE FALSE END                     AS is_weekend,
    CASE WHEN DAYOFWEEK(date_day) NOT IN (0, 6)
         THEN TRUE ELSE FALSE END                     AS is_weekday,
    CASE WHEN date_day = DATE_TRUNC('month', date_day)
         THEN TRUE ELSE FALSE END                     AS is_first_day_of_month,
    CASE WHEN date_day = LAST_DAY(date_day)
         THEN TRUE ELSE FALSE END                     AS is_last_day_of_month,

    -- Relative flags (useful for dashboard filters)
    CASE WHEN date_day = CURRENT_DATE()
         THEN TRUE ELSE FALSE END                     AS is_today,
    CASE WHEN date_day >= DATE_TRUNC('month', CURRENT_DATE())
         AND date_day <= CURRENT_DATE()
         THEN TRUE ELSE FALSE END                     AS is_current_month,
    CASE WHEN YEAR(date_day) = YEAR(CURRENT_DATE())
         THEN TRUE ELSE FALSE END                     AS is_current_year

  FROM date_spine

)

SELECT * FROM final