-- Weekly sales by store and holiday

SELECT
    f.store_id,
    d.isholiday,
    SUM(f.store_weekly_sales) as weekly_sales
FROM 
    walmartdb.transform.walmart_fact_table f 
JOIN walmartdb.transform.walmart_date_dim d
ON f.date_id = d.date_id
GROUP BY f.store_id, d.isholiday
ORDER BY f.store_id, d.isholiday;

SELECT
    f.temperature,
    year(d.date) as  year,
    SUM(f.store_weekly_sales) as weekly_sales
FROM 
    walmartdb.transform.walmart_fact_table f 
JOIN walmartdb.transform.walmart_date_dim d
ON f.date_id = d.date_id
GROUP BY f.temperature, year(d.date) 
ORDER BY f.temperature, year(d.date);


SELECT
    YEAR(dp.date) AS sales_year,
    CASE
        WHEN f.temperature < 32 THEN 'Below 32°F'
        WHEN f.temperature BETWEEN 32 AND 50 THEN '32-50°F'
        WHEN f.temperature BETWEEN 51 AND 70 THEN '51-70°F'
        WHEN f.temperature BETWEEN 71 AND 90 THEN '71-90°F'
        ELSE 'Above 90°F'
    END AS temperature_range,
    SUM(f.store_weekly_sales) AS total_weekly_sales,
    AVG(f.temperature) AS avg_temperature
FROM walmartdb.transform.walmart_fact_table f
JOIN walmartdb.transform.walmart_date_dim dp
    ON f.date_id = dp.date_id
GROUP BY YEAR(dp.date), temperature_range
ORDER BY sales_year, temperature_range;

SELECT 
    s.store_id,
    s.store_size,
    SUM(f.store_weekly_sales) as weekly_sales
FROM 
    walmartdb.transform.walmart_store_dim s 
JOIN walmartdb.transform.walmart_fact_table f 
ON s.store_id = f.store_id
AND s.dept_id = f.dept_id
GROUP BY s.store_id,s.store_size
ORDER BY weekly_sales desc;

-- SELECT *
-- FROM (

SELECT * 
FROM (SELECT
    MONTHNAME(d.date) as Month,
    s.store_type,
    f.store_weekly_sales
FROM 
    walmartdb.transform.walmart_fact_table f 
JOIN walmartdb.transform.walmart_date_dim d 
ON f.date_id = d.date_id
JOIN walmartdb.transform.walmart_store_dim s 
ON s.store_id = f.store_id
AND s.dept_id = f.dept_id)
PIVOT (
sum(store_weekly_sales) for store_type in ('A','B','C')
)as pivoted
ORDER BY Month;

SELECT
    f.store_id,
    YEAR(d.date) as year,
    SUM(f.markdown1) as markdown1,
    SUM(f.markdown2) as markdown2,
    SUM(f.markdown3) as markdown3,
    SUM(f.markdown4) as markdown4,
    SUM(f.markdown5) as markdown5    
FROM 
    walmartdb.transform.walmart_fact_table f
JOIN walmartdb.transform.walmart_date_dim d
ON f.date_id = d.date_id
WHERE f.markdown1 IS NOT NULL
GROUP BY f.store_id,YEAR(d.date)
ORDER BY store_id,year;

SELECT *
FROM (SELECT
    -- s.store_id,
    s.store_type,
    f.store_weekly_sales
FROM 
    walmartdb.transform.walmart_fact_table f 
JOIN walmartdb.transform.walmart_store_dim s 
ON f.store_id = s.store_id
AND f.dept_id = s.dept_id)
pivot (
sum(store_weekly_sales) FOR store_type IN ('A','B','C')
)pivoted;
-- ORDER BY store_id;

SELECT
    f.store_id,
    YEAR(d.date) as year,
    SUM(f.fuel_price) as fuel_price   
FROM 
    walmartdb.transform.walmart_fact_table f 
JOIN walmartdb.transform.walmart_date_dim d 
ON f.date_id = d.date_id
GROUP BY f.store_id, YEAR(d.date)
ORDER BY store_id, year;

SELECT
    YEAR(d.date) as year,
    MONTHNAME(d.date) as Month,
    EXTRACT(DAY FROM d.date) as Date,
    SUM(f.store_weekly_sales) as weekly_sales
FROM 
    walmartdb.transform.walmart_fact_table f 
JOIN walmartdb.transform.walmart_date_dim d 
ON f.date_id = d.date_id
GROUP BY YEAR(d.date),MONTHNAME(d.date),EXTRACT(DAY FROM d.date)
ORDER BY year,month,date;

SELECT
    cpi,
    SUM(store_weekly_sales) as weekly_sales
FROM 
    walmartdb.transform.walmart_fact_table 
GROUP BY cpi
ORDER BY cpi;

SELECT
    dept_id,
    SUM(store_weekly_sales) as weekly_sales
FROM 
    walmartdb.transform.walmart_fact_table
GROUP BY dept_id
ORDER BY weekly_sales DESC
LIMIT 5;
