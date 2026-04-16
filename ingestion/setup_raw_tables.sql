-- ═══════════════════════════════════════════════════════
-- RAW TABLE SETUP  — run once after  terraform apply
-- Creates tables in RAW_DB.BRONZE and loads sample CSVs
-- Role: LOADER_SVC_USER (or SYSADMIN for one-off setup)
-- ═══════════════════════════════════════════════════════

USE ROLE    SYSADMIN;
USE DATABASE RAW_DB;
USE SCHEMA   BRONZE;
USE WAREHOUSE INGEST_WH;

-- ────────────────────────────────────────────────────────
-- RAW TABLES
-- All columns VARCHAR — casting happens in Silver layer
-- _ingested_at / _source_file are Snowpipe metadata cols
-- ────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS raw_customers (
  customer_id       VARCHAR,
  first_name        VARCHAR,
  last_name         VARCHAR,
  email             VARCHAR,
  phone             VARCHAR,
  city              VARCHAR,
  state             VARCHAR,
  country           VARCHAR,
  signup_date       VARCHAR,
  customer_segment  VARCHAR,
  _ingested_at      TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
  _source_file      VARCHAR       DEFAULT 'manual_seed'
);

CREATE TABLE IF NOT EXISTS raw_orders (
  order_id     VARCHAR,
  customer_id  VARCHAR,
  product_id   VARCHAR,
  order_date   VARCHAR,
  ship_date    VARCHAR,
  status       VARCHAR,
  quantity     VARCHAR,
  unit_price   VARCHAR,
  discount     VARCHAR,
  region       VARCHAR,
  _ingested_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
  _source_file VARCHAR       DEFAULT 'manual_seed'
);

CREATE TABLE IF NOT EXISTS raw_products (
  product_id    VARCHAR,
  product_name  VARCHAR,
  category      VARCHAR,
  subcategory   VARCHAR,
  brand         VARCHAR,
  cost_price    VARCHAR,
  list_price    VARCHAR,
  is_active     VARCHAR,
  created_date  VARCHAR,
  _ingested_at  TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
  _source_file  VARCHAR       DEFAULT 'manual_seed'
);

-- ────────────────────────────────────────────────────────
-- INTERNAL STAGE  (temp stage for CSV upload)
-- ────────────────────────────────────────────────────────
CREATE STAGE IF NOT EXISTS raw_stage
  FILE_FORMAT = (
    TYPE             = 'CSV'
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    SKIP_HEADER      = 1
    NULL_IF          = ('', 'NULL')
    EMPTY_FIELD_AS_NULL = TRUE
  );

-- ────────────────────────────────────────────────────────
-- LOAD DATA
-- Run these PUT commands from SnowSQL CLI:
--
--   snowsql -a <org>-<account> -u <user>
--   USE ROLE SYSADMIN; USE DATABASE RAW_DB; USE SCHEMA BRONZE;
--   PUT file:///path/to/ingestion/sample_data/customers_20240101.csv @raw_stage;
--   PUT file:///path/to/ingestion/sample_data/orders_20240101.csv   @raw_stage;
--   PUT file:///path/to/ingestion/sample_data/products_20240101.csv @raw_stage;
--
-- Then run the COPY INTO statements below:
-- ────────────────────────────────────────────────────────

COPY INTO raw_customers (
  customer_id, first_name, last_name, email, phone,
  city, state, country, signup_date, customer_segment,
  _ingested_at, _source_file
)
FROM (
  SELECT
    $1, $2, $3, $4, $5, $6, $7, $8, $9, $10,
    CURRENT_TIMESTAMP(),
    METADATA$FILENAME
  FROM @raw_stage/customers_20240101.csv.gz
)
ON_ERROR = 'ABORT_STATEMENT';

COPY INTO raw_orders (
  order_id, customer_id, product_id, order_date, ship_date,
  status, quantity, unit_price, discount, region,
  _ingested_at, _source_file
)
FROM (
  SELECT
    $1, $2, $3, $4, $5, $6, $7, $8, $9, $10,
    CURRENT_TIMESTAMP(),
    METADATA$FILENAME
  FROM @raw_stage/orders_20240101.csv.gz
)
ON_ERROR = 'ABORT_STATEMENT';

COPY INTO raw_products (
  product_id, product_name, category, subcategory, brand,
  cost_price, list_price, is_active, created_date,
  _ingested_at, _source_file
)
FROM (
  SELECT
    $1, $2, $3, $4, $5, $6, $7, $8, $9,
    CURRENT_TIMESTAMP(),
    METADATA$FILENAME
  FROM @raw_stage/products_20240101.csv.gz
)
ON_ERROR = 'ABORT_STATEMENT';

-- ────────────────────────────────────────────────────────
-- VERIFY
-- ────────────────────────────────────────────────────────
SELECT 'raw_customers' AS tbl, COUNT(*) AS rows FROM raw_customers
UNION ALL
SELECT 'raw_orders',           COUNT(*)           FROM raw_orders
UNION ALL
SELECT 'raw_products',         COUNT(*)           FROM raw_products;
