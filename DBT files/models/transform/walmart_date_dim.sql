{{
    config(
        materialized = 'incremental',
        incremental_strategy = 'merge',
        unique_key = 'date_id',
        merge_update_columns = ['date','isholiday','load_timestamp','record_hash','update_date'],
        schema = 'TRANSFORM'
    )
}}

with date_src as (

    select
        to_char(date, 'YYYYMMDD') as date_id,
        date,
        max(isholiday) as isholiday,
        max(load_timestamp) as load_timestamp,
        MD5(CONCAT(date::varchar, '|', max(isholiday)::varchar)) as record_hash
    from {{ ref('department_raw') }}
    group by date

    {% if is_incremental() %}
    having max(load_timestamp) > (select coalesce(max(load_timestamp), '1900-01-01') from {{ this }})
    {% endif %}

),

{% if is_incremental() %}
existing as (

    select
        date_id,
        record_hash as old_record_hash,
        update_date as old_update_date
    from {{ this }}

),
{% endif %}

walmart_date_dim as (

    select
        s.date_id,
        s.date,
        s.isholiday,
        s.load_timestamp,
        s.record_hash,
        current_timestamp as insert_date,
        {% if is_incremental() %}
        case
            when e.old_record_hash is null then current_timestamp          
            when e.old_record_hash != s.record_hash then current_timestamp
            else e.old_update_date                                        
        end as update_date
        from date_src s
        left join existing e
            on s.date_id = e.date_id
        {% else %}
        current_timestamp as update_date
    from date_src s
        {% endif %}

)

select
    date_id,
    date,
    isholiday,
    load_timestamp,
    record_hash,
    insert_date,
    update_date
from walmart_date_dim