{{ 
    config (
        materialized = 'table',
        schema = 'TRANSFORM'
    )
}}

with date_dim as (
    SELECT
    date_id,
    date
    FROM {{ref('walmart_date_dim')}}
),

store_dim as (
    SELECT
        store_id,
        dept_id
    FROM {{ ref('walmart_store_dim')}}
),

dept_src as (
    SELECT
        STORE,
        DEPT,
        DATE,
        WEEKLY_SALES         
    FROM {{ ref('department_raw') }}
),

fact_src as (
    SELECT
    STORE,
    DATE,
    TEMPERATURE,
    FUEL_PRICE,
    MARKDOWN1,
    MARKDOWN2,
    MARKDOWN3,
    MARKDOWN4,
    MARKDOWN5,
    CPI,
    UNEMPLOYMENT
    FROM {{ref('fact_raw')}}
),
walmart_fact_src as (
    SELECT
    s.store_id,
    s.dept_id,
    d.date_id,
    dp.weekly_sales as store_weekly_sales,
    f.fuel_price,
    f.temperature,
    f.unemployment,
    f.cpi,
    f.markdown1,
    f.markdown2,
    f.markdown3,
    f.markdown4,
    f.markdown5,
    current_timestamp(6) as insert_date,
    current_timestamp(6) as update_date
    FROM
    store_dim s
    join dept_src dp 
    on s.store_id = dp.store
    and s.dept_id = dp.dept
    join date_dim d 
    on dp.date = d.date
    join fact_src f 
    on s.store_id = f.store
)
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
FROM walmart_fact_src

