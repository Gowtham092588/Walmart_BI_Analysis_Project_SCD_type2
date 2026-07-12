{{
    config(
        materialized = 'view',
        schema = 'MARTS'
    )
}}

with walmart_fact_view as (
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
    dbt_valid_from as vrsn_start_date,
    coalesce(dbt_valid_to, '9999-12-31 00:00:00.000') as vrsn_end_date,
    insert_date,
    update_date
    FROM {{ref('walmart_fact_snapshot')}}
)
SELECT * FROM walmart_fact_view