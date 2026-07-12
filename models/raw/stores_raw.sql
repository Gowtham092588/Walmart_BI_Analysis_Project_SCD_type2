{{ 
    config (
        materialized = "table",
        pre_hook = "{{ copy_csvs('STORES_CP') }}",
        schema = 'RAW_DATA'

    )
}}

WITH stores_raw AS 
(
    SELECT 
    STORE,
	TYPE,
	SIZE,
    CURRENT_TIMESTAMP(6) AS CREATED_AT
    FROM {{source('stores','STORES_CP')}}
)
SELECT
STORE,
TYPE,
SIZE,
CAST(CREATED_AT AS TIMESTAMP(6)) AS CREATED_AT
FROM stores_raw