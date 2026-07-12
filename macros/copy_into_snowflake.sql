{% macro copy_csvs(target_table) %}

    {# Fetch configurations from dbt_project.yml #}
    {% set stage_name = var('stage_name') %}
    {% set file_format_name = var('file_format') %}
    {% set table_mappings = var('table_mappings') %}
    
    {# Isolate ONLY the file name mapped to the requested target table #}
    {% set file_name = table_mappings.get(target_table) %}

    {% if file_name %}
        
        {% set truncate_sql %}
            TRUNCATE TABLE {{ target_table }};
        {% endset %}

        {% set copy_sql %}
            COPY INTO {{ target_table }}
            FROM @{{ stage_name }}/{{ file_name }}
            FILE_FORMAT = (FORMAT_NAME = '{{ file_format_name }}')
            ON_ERROR = 'ABORT_STATEMENT'
            PURGE = FALSE;
        {% endset %}

        {# Execute isolated statements #}
        {{ log("Truncating target table: " ~ target_table, info=True) }}
        {% do run_query(truncate_sql) %}

        {{ log("Loading isolated data into: " ~ target_table ~ " from " ~ file_name, info=True) }}
        {% do run_query(copy_sql) %}
        {{ log("Successfully reloaded data into: " ~ target_table, info=True) }}

    {% else %}
        {# Fail explicitly if someone passes an unmapped table name #}
        {{ exceptions.raise_compiler_error("ERROR: No CSV file mapping found in dbt_project.yml for target table: " ~ target_table) }}
    {% endif %}

{% endmacro %}




 

