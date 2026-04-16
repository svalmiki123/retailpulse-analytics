{% macro unload_to_s3(
    table_ref,
    s3_path,
    partition_by=None
) %}
  {#-
    unload_to_s3: Exports a Snowflake table to S3 as gzipped CSV.

    Usage:
      {{ unload_to_s3(this, 'fct_orders') }}
      {{ unload_to_s3(this, 'dim_customers', partition_by='customer_segment') }}
  -#}

  {%- set stage = '@RAW_DB.BRONZE.RETAILPULSE_UNLOAD_STAGE' -%}
  {%- set dated_path = s3_path
      ~ '/year=' ~ modules.datetime.datetime.now().strftime('%Y')
      ~ '/month=' ~ modules.datetime.datetime.now().strftime('%m')
      ~ '/day=' ~ modules.datetime.datetime.now().strftime('%d')
      ~ '/' -%}

  COPY INTO {{ stage }}/{{ dated_path }}
  FROM (
    SELECT *
    FROM {{ table_ref }}
    {%- if partition_by is not none %}
    ORDER BY {{ partition_by }}
    {%- endif %}
  )
  FILE_FORMAT = (
    TYPE = CSV
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    NULL_IF = ('')
    EMPTY_FIELD_AS_NULL = TRUE
    COMPRESSION = GZIP
  )
  SINGLE = FALSE
  INCLUDE_QUERY_ID = TRUE

{% endmacro %}