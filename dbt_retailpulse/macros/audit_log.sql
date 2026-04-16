{% macro audit_log(model_name=this.name) %}
  {#-
    audit_log: Records a row in dbt_audit_log after a model runs.
    Use as a post-hook on Gold models.

    Usage in model config:
      {{ config(post_hook="{{ audit_log() }}") }}
  -#}

  INSERT INTO DEV_DB.GOLD.dbt_audit_log (
    run_id,
    model_name,
    schema_name,
    database_name,
    materialization,
    run_started_at,
    run_completed_at,
    row_count,
    status,
    dbt_version,
    target_name
  )
  SELECT
    '{{ invocation_id }}'                     AS run_id,
    '{{ model_name }}'                        AS model_name,
    '{{ this.schema }}'                       AS schema_name,
    '{{ this.database }}'                     AS database_name,
    '{{ config.get("materialized") }}'        AS materialization,
    CURRENT_TIMESTAMP()                       AS run_started_at,
    CURRENT_TIMESTAMP()                       AS run_completed_at,
    COUNT(*)                                  AS row_count,
    'success'                                 AS status,
    '{{ dbt_version }}'                       AS dbt_version,
    '{{ target.name }}'                       AS target_name
  FROM {{ this }}

{% endmacro %}