# 🛍️ RetailPulse Analytics Platform

> A production-grade end-to-end modern data platform built from scratch in 14 days.

[![dbt](https://img.shields.io/badge/dbt-1.11-orange)](https://www.getdbt.com/)
[![Snowflake](https://img.shields.io/badge/Snowflake-Enterprise-blue)](https://www.snowflake.com/)
[![Terraform](https://img.shields.io/badge/Terraform-0.94-purple)](https://www.terraform.io/)
[![GitHub Actions](https://img.shields.io/badge/CI%2FCD-GitHub_Actions-black)](https://github.com/features/actions)

---

## 🏗️ Architecture

```
S3 Data Lake (raw/ processed/ unload/)
          ↓
Snowpipe Auto-ingest (event-driven via SQS)
          ↓
Bronze Layer — RAW_DB.BRONZE (raw VARCHAR tables)
          ↓
Silver Layer — DEV_DB.SILVER (typed, incremental, deduplicated)
          ↓
Gold Layer — DEV_DB.GOLD (star schema: fct_orders + 3 dims)
          ↓
Semantic Layer — MetricFlow (14 standardized KPIs)
          ↓
┌─────────────────┬──────────────────────────────┐
│ Streamlit       │ Claude AI NLP Query Engine   │
│ Dashboard       │ (Text-to-SQL on Gold schema) │
└─────────────────┴──────────────────────────────┘
```

---

## 🛠️ Tech Stack

| Layer | Technology | Purpose |
|---|---|---|
| Infrastructure | **Terraform** | Snowflake IaC — warehouses, roles, users, databases |
| Ingestion | **AWS S3 + Snowpipe** | Event-driven auto-ingest via SQS |
| Transformation | **dbt Core 1.11** | Bronze → Silver → Gold |
| Semantic Layer | **MetricFlow** | 14 standardized business metrics |
| CI/CD | **GitHub Actions** | Slim CI on PRs, prod deploy on merge |
| Reporting | **Streamlit** | Interactive dashboard on Gold layer |
| AI Layer | **Claude API** | Natural language → SQL query engine |
| Data Lake | **AWS S3** | Raw + processed + unload zones |

---

## 📐 Data Models

### Medallion Architecture

```
Bronze  → raw VARCHAR tables, append-only, _ingested_at metadata
Silver  → typed, incremental, deduplicated, surrogate keys
Gold    → star schema, denormalized for query performance
Semantic → MetricFlow metrics, single source of truth for KPIs
```

### Star Schema (Gold Layer)

```
          dim_date
             │
dim_products ──fct_orders── dim_customers
```

| Model | Rows | Grain | Key Columns |
|---|---|---|---|
| fct_orders | 1/order | order_id | revenue, quantity, days_to_ship |
| dim_customers | 1/customer | customer_id | value_tier, lifetime_value |
| dim_products | 1/product | product_id | margin_pct, performance_tier |
| dim_date | 1/date | date_day | is_weekend, quarter_name |

---

## 🚀 Key Features

### Infrastructure as Code
Every Snowflake object — warehouses, roles, users, databases, schemas,
grants — managed by Terraform. Zero UI clicking. Full version history.

### Event-Driven Ingestion
S3 file drop → SQS notification → Snowpipe → Bronze table.
Latency under 60 seconds. Zero scheduled jobs.

### Incremental Models with Late Arrival Protection
Silver models use 3-hour lookback window — catches late-arriving
Snowpipe data without reprocessing everything.

### Macro Library
- `unload_to_s3` — exports any Gold table to S3 as post-hook
- `audit_log` — records row counts and run metadata per model
- `safe_cast` — TRY_CAST wrapper with default values
- `generate_schema_name` — correct schema isolation per layer

### Automated CI/CD
- PR → slim CI tests only changed models + downstream
- Merge to main → full prod build + manifest upload to S3
- Terraform plan on PR, apply on merge

### AI Query Engine
Claude API + schema context injection → accurate Text-to-SQL
on the Gold layer. Business users ask questions in plain English.

---

## 📁 Project Structure

```
retailpulse-analytics/
├── terraform/
│   ├── environments/dev/     # main.tf, variables, warehouses, roles, users, databases
│   └── modules/              # reusable Terraform modules
├── dbt_retailpulse/
│   ├── models/
│   │   ├── bronze/           # source views + freshness checks
│   │   ├── silver/           # incremental typed models
│   │   ├── gold/             # star schema facts + dims
│   │   └── semantic/         # MetricFlow models + metrics
│   ├── macros/               # unload_to_s3, audit_log, safe_cast
│   ├── snapshots/            # SCD Type 2 customer history
│   └── profiles/             # CI/CD profiles.yml
├── ingestion/
│   ├── sample_data/          # retail CSV test files
│   ├── snowpipe/             # SQS + S3 notification configs
│   └── streamlit/            # dashboard + AI query engine
├── .github/workflows/        # CI + CD + Terraform pipelines
└── docs/                     # architecture + daily log
```

---

## ⚡ Quick Start

```bash
# 1. Clone
git clone https://github.com/YOUR_USERNAME/retailpulse-analytics.git
cd retailpulse-analytics

# 2. Deploy Snowflake infrastructure
cd terraform/environments/dev
cp example.tfvars terraform.tfvars
# Fill in your Snowflake credentials
terraform init && terraform apply -var-file=terraform.tfvars

# 3. Run dbt pipeline
cd ../../dbt_retailpulse
python3 -m venv venv && source venv/bin/activate
pip install dbt-core dbt-snowflake
dbt deps && dbt build --select bronze silver gold

# 4. Launch AI query engine
cd ../ingestion/streamlit
pip install streamlit anthropic snowflake-connector-python plotly python-dotenv
cp .env.example .env  # Fill in your credentials
streamlit run nlp_query_engine_local.py
```

---

## 📊 Metrics Defined

| Metric | Type | Description |
|---|---|---|
| total_revenue | simple | Sum of revenue excluding PENDING |
| completed_revenue | simple | Revenue from COMPLETED orders only |
| avg_order_value | simple | Average revenue per order |
| order_count | simple | Total orders placed |
| units_sold | simple | Total units across all orders |
| return_count | simple | Orders returned |
| return_rate | ratio | return_count / order_count |
| customer_count | simple | Unique customers |
| avg_customer_ltv | simple | Average lifetime value |
| total_customer_ltv | simple | Sum of all LTV |
| avg_days_to_ship | simple | Average order-to-ship days |
| cumulative_revenue | cumulative | Running revenue total |

---

## 🔧 Infrastructure Summary

| Object | Name | Role |
|---|---|---|
| Warehouses | INGEST_WH, TRANSFORM_WH, REPORTING_WH | Isolated by workload |
| Roles | RAW_LOADER_ROLE, DBT_ROLE, ANALYST_ROLE, REPORTER_ROLE | Least privilege |
| Databases | RAW_DB, DEV_DB, PROD_DB | Isolated by environment |
| Schemas | BRONZE, SILVER, GOLD, SEMANTIC | Medallion layers |

---

## 👨‍💻 Author

**Sivasai Valmiki** — Data Architect/Director

Built in 7 days · 28 hours · Mentored by Claude AI
