{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        unique_key=['store_id', 'dept_id'],
        merge_exclude_columns=['insert_date'],
        schema='TRANSFORM'
    )
}}

WITH dept_raw AS (

    SELECT
        STORE,
        DEPT,
        CREATED_AT         
    FROM {{ ref('department_raw') }}
    GROUP BY STORE, DEPT, CREATED_AT

),

store_raw AS (

    SELECT
        STORE,
        TYPE,
        SIZE
    FROM {{ ref('stores_raw') }}

),

walmart_store_dim AS (
    SELECT
        d.store AS store_id,
        d.dept AS dept_id,
        s.type AS store_type,
        s.size AS store_size,
        CURRENT_TIMESTAMP(6) AS insert_date,
        CURRENT_TIMESTAMP(6) AS update_date,
        d.created_at
    FROM dept_raw d
    LEFT JOIN store_raw s
        ON d.store = s.store

    {% if is_incremental() %}
    WHERE d.created_at >
        (
        SELECT MAX(update_date) FROM {{ this }}
        )
    {% endif %}
)
SELECT
    store_id,
    dept_id,
    store_type,
    store_size,
    insert_date,
    update_date
FROM walmart_store_dim