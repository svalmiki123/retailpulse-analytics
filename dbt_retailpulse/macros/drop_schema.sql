{% macro drop_schema(schema_name) %}
  {#-
    Drops a schema and all its contents.
    Used by CI pipeline to clean up temporary CI schemas.
    Only runs in CI target — safety check prevents accidental drops.
  -#}

  {% if target.name == 'ci' %}
    DROP SCHEMA IF EXISTS {{ target.database }}.{{ schema_name }} CASCADE;
    {{ log("Dropped CI schema: " ~ target.database ~ "." ~ schema_name, info=True) }}
  {% else %}
    {{ log("drop_schema skipped — target is " ~ target.name ~ " not ci", info=True) }}
  {% endif %}

{% endmacro %}