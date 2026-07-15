{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        unique_key=['store_id', 'dept_id'],
        merge_update_columns=['store_type','store_size','load_timestamp','record_hash','update_date'],
        schema='TRANSFORM'
    )
}}

with dept_raw as (

    select
        store,
        dept,
        load_timestamp
    from {{ ref('department_raw') }}
    qualify row_number() over (
        partition by store, dept
        order by load_timestamp desc
    ) = 1

),

store_raw as (

    select
        store,
        type,
        size
    from {{ ref('stores_raw') }}

),

joined as (

    select
        d.store as store_id,
        d.dept as dept_id,
        s.type as store_type,
        s.size as store_size,
        d.load_timestamp,
        MD5(CONCAT(s.type::varchar, '|', s.size::varchar)) as record_hash
    from dept_raw d
    left join store_raw s
        on d.store = s.store

    {% if is_incremental() %}
    where d.load_timestamp > (
        select coalesce(max(load_timestamp), '1900-01-01') from {{ this }}
    )
    {% endif %}

),

{% if is_incremental() %}
existing as (

    select
        store_id,
        dept_id,
        record_hash as old_record_hash,
        update_date as old_update_date
    from {{ this }}

),
{% endif %}

walmart_store_dim as (

    select
        j.store_id,
        j.dept_id,
        j.store_type,
        j.store_size,
        j.load_timestamp,
        j.record_hash,
        current_timestamp(6) as insert_date,
        {% if is_incremental() %}
        case
            when e.old_record_hash is null then current_timestamp(6)          
            when e.old_record_hash != j.record_hash then current_timestamp(6) 
            else e.old_update_date                                            
        end as update_date
    from joined j
    left join existing e
        on j.store_id = e.store_id
        and j.dept_id = e.dept_id
        {% else %}
        current_timestamp(6) as update_date
    from joined j
        {% endif %}

)

select
    store_id,
    dept_id,
    store_type,
    store_size,
    load_timestamp,
    record_hash,
    insert_date,
    update_date
from walmart_store_dim