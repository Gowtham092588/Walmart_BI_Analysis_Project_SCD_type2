{% snapshot walmart_fact_snapshot %}

{{
    config (
        target_database='WALMARTDB',
        target_schema='snapshots',
        unique_key=['store_id', 'dept_id', 'date_id'],
        strategy='check',
        check_cols=['store_weekly_sales', 'fuel_price', 'temperature', 'unemployment', 'cpi']
    )
}}
SELECT
    store_id,
    dept_id,
    date_id,
    store_weekly_sales,
    fuel_price,
    temperature,
    unemployment,
    cpi,
    markdown1,
    markdown2,
    markdown3,
    markdown4,
    markdown5,
    insert_date,
    update_date
FROM {{ref ('walmart_fact_table') }}

{% endsnapshot %}