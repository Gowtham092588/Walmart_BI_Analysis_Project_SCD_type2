{{
    config (
        materialized = 'incremental',
        incremental_strategy ='merge',
        unique_key='date_id',
        merge_exclude_columns = ['insert_date'],
        schema = 'TRANSFORM'
    )
}}

with walmart_date_dim as (

    select distinct
        to_char("DATE", 'YYYYMMDD') date_id,
        "DATE" as date,
        isholiday,
        created_at,
        current_timestamp as insert_date,
        current_timestamp as update_date
    from {{ ref ('department_raw')}}

    {% if is_incremental() %}
    where created_at > (select max(update_date) from {{this}})    
    {% endif %}

)

select
    date_id,
    date,
    isholiday,
    insert_date,
    update_date
from walmart_date_dim