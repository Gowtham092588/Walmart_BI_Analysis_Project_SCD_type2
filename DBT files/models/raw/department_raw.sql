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
	SUM(WEEKLY_SALES) as WEEKLY_SALES,
	MAX(ISHOLIDAY) as ISHOLIDAY,
    CURRENT_TIMESTAMP(6) AS LOAD_TIMESTAMP
    FROM {{source('department','DEPARTMENT_CP')}}
    GROUP BY
        STORE,
        DEPT,
        DATE
)
SELECT
STORE,
DEPT,
DATE,
CAST(WEEKLY_SALES AS FLOAT) AS WEEKLY_SALES,
CAST(ISHOLIDAY AS VARCHAR) AS ISHOLIDAY,
LOAD_TIMESTAMP
FROM department_raw
