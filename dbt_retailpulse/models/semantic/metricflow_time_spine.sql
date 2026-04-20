{{
  config(
    materialized='table',
    tags=['semantic', 'timespine']
  )
}}

WITH spine AS (
  SELECT
    DATEADD(
      DAY,
      SEQ4(),
      '2020-01-01'::DATE
    ) AS date_day
  FROM TABLE(GENERATOR(ROWCOUNT => 3653))  -- 10 years of daily granularity
)

SELECT
  date_day
FROM spine
WHERE date_day <= CURRENT_DATE() + INTERVAL '1 year'
ORDER BY date_day
