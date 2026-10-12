# Welcome to Walmart BI Analysis Project!

# Overview

This project implements an automated cloud native ELT analytics platform on AWS, Snowflake and DBT to unify Walmart’s weekly departement sales to metadata and macroeconomic indicators.

## Business Objective

The automated S3 → Snowflake → dbt → Tableau pipeline reduced manual preparation by 90%+ and provided consistent data for store performance, inventory planning, promotion analysis, and ROI reporting.

## Architecture

<img width="1081" height="548" alt="image" src="https://github.com/user-attachments/assets/cc238df0-726c-4b78-af69-07502faf75d4" />


## Key Steps

## Ingestion & Staging: 
* Modular Python scripts ingest the weekly CSV source files and stage them securely in Amazon S3. 
* Access is controlled through IAM roles, S3 data is protected using AWS KMS encryption, and Snowflake Storage Integration is used so Snowflake can access S3 without storing AWS credentials.

## Cloud Data Warehouse: 
* Snowflake acts as the centralized data platform. 
* Data is isolated using separate databases and schemas such as RAW_DB, ANALYTICS_DEV, and ANALYTICS_PROD.
* X-Small auto-scaling warehouses are used, with separate compute for transformation workloads and Tableau queries to avoid workload conflicts and control cost.

## Transformation & Governance: 
* DBT manages SQL transformations, lineage, incremental processing, automated data-quality tests, dimensional models, SCD Type 1, and SCD Type 2 history tracking. 
* Snowflake RBAC controls access to raw, development, production, and reporting objects.

## Orchestration: 
* The end-to-end pipeline is triggered by a scheduled GitHub Actions workflow. 
* The automated DAG runs in sequence: Python ingestion → S3 staging → Snowflake COPY INTO load using JSON/config metadata → dbt build and tests → Tableau extract refresh. Each step runs only after the previous step completes successfully.

## Consumption: 
* Tableau connects directly to the curated marts/Gold layer in Snowflake to deliver interactive dashboards for executives, Merchandising, Finance, and Supply Chain teams.


### Author

**Gowtham Kethineni**  
https://www.linkedin.com/in/gowtham-kethineni
