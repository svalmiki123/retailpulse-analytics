{% macro date_trunc(datepart, date) %}
    DATE_TRUNC('{{ datepart }}', {{ date }})
{% endmacro %}

{% macro datediff(datepart, start_date, end_date) %}
    DATEDIFF('{{ datepart }}', {{ start_date }}, {{ end_date }})
{% endmacro %}

{% macro current_timestamp_ntz() %}
    CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP())::TIMESTAMP_NTZ
{% endmacro %}

{% macro fiscal_year(date_column, start_month=1) %}
  {#- Returns fiscal year. start_month=4 means fiscal year starts in April -#}
  {%- if start_month == 1 -%}
    YEAR({{ date_column }})
  {%- else -%}
    CASE
      WHEN MONTH({{ date_column }}) >= {{ start_month }}
      THEN YEAR({{ date_column }})
      ELSE YEAR({{ date_column }}) - 1
    END
  {%- endif -%}
{% endmacro %}