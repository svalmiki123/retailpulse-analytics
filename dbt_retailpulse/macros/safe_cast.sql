{% macro safe_cast(column_name, target_type, default_value=None) %}
  {#-
    safe_cast: Casts a column to target_type using TRY_CAST.
    If the cast fails, returns default_value instead of erroring.

    Usage:
      {{ safe_cast('order_id', 'INT') }}
      {{ safe_cast('unit_price', 'FLOAT', 0.0) }}
      {{ safe_cast('order_date', 'DATE') }}
  -#}
  {%- if default_value is not none -%}
    COALESCE(TRY_CAST({{ column_name }} AS {{ target_type }}), {{ default_value }})
  {%- else -%}
    TRY_CAST({{ column_name }} AS {{ target_type }})
  {%- endif -%}
{% endmacro %}