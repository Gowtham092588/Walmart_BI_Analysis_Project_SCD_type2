{{ 
    config (
        materialized = "table",
        pre_hook = "{{ copy_csvs('DEPARTMENT_CP') }}",
        schema = 'RAW_DATA'

    )
}}

WITH department_raw AS 
(
    SELECT 
    STORE,
	DEPT,
	DATE,
	WEEKLY_SALES,
	ISHOLIDAY,
    CURRENT_TIMESTAMP(6) AS CREATED_AT
    FROM {{source('department','DEPARTMENT_CP')}}
)
SELECT
STORE,
DEPT,
DATE,
CAST(WEEKLY_SALES AS FLOAT) AS WEEKLY_SALES,
CAST(ISHOLIDAY AS VARCHAR) AS ISHOLIDAY,
CAST(CREATED_AT AS TIMESTAMP(6)) AS CREATED_AT
FROM department_raw
