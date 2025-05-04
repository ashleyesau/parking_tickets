{% macro preview_table(table_name, limit=10) %}
    {% set sql %}
        SELECT * FROM {{ table_name }} LIMIT {{ limit }}
    {% endset %}

    {% do run_query(sql) %}
{% endmacro %}
