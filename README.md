# 🛍️ RetailPulse Analytics Platform

> End-to-end modern data platform: S3 → Snowflake → dbt → Semantic Layer → Streamlit + Claude AI

## Stack

| Tool | Purpose |
|------|---------|
| **Terraform** | Snowflake infrastructure as code |
| **AWS S3** | Data lake — raw / processed / unload zones |
| **Snowpipe** | Auto-ingest S3 → Bronze tables |
| **dbt Core** | Transform Bronze → Silver → Gold |
| **MetricFlow** | Semantic layer & unified KPIs |
| **GitHub Actions** | CI/CD for dbt + Terraform |
| **Streamlit** | Interactive reporting dashboard |
| **Claude AI** | Natural language query interface |

## Architecture
See [Architecture Doc](docs/architecture/ARCHITECTURE.md)

## Project Structure
retailpulse-analytics/
├── terraform/                  # Snowflake infrastructure as code
│   ├── modules/                # Reusable Terraform modules
│   │   ├── snowflake_warehouse/
│   │   ├── snowflake_roles/
│   │   └── snowflake_databases/
│   └── environments/           # dev and prod variable files
├── dbt_retailpulse/            # dbt project root
│   ├── models/
│   │   ├── bronze/             # Raw typed source models
│   │   ├── silver/             # Cleaned & conformed models
│   │   ├── gold/               # Fact & dimension tables
│   │   └── semantic/           # MetricFlow metric definitions
│   ├── macros/                 # Reusable Jinja2 macros incl. S3 unload
│   └── snapshots/              # SCD Type 2 change tracking
├── ingestion/                  # Snowpipe config + sample data
├── .github/workflows/          # GitHub Actions CI/CD pipelines
└── docs/                       # Architecture & daily progress log
## Author
Your Name — Siva Valmiki