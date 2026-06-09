-- ============================================================
-- Athena SQL: Create Silver External Tables
-- Project: COVID-19 Analytics AWS Pipeline
-- Notes:
--   - This project did NOT use AWS Glue Crawler.
--   - Athena CREATE EXTERNAL TABLE stores metadata in AWS Glue Data Catalog.
--   - MSCK REPAIR TABLE registers partition folders.
-- ============================================================

CREATE DATABASE IF NOT EXISTS covid_silver_db;


CREATE EXTERNAL TABLE IF NOT EXISTS covid_silver_db.cases_standardized (
    full_date  DATE,
    state_name STRING,
    cases_cum  BIGINT,
    deaths_cum BIGINT
)
PARTITIONED BY (
    state_code STRING,
    year       INT,
    month      INT,
    day        INT
)
STORED AS PARQUET
LOCATION 's3://covid-19-analytics-avishek/covid/silver/cases_standardized/';

MSCK REPAIR TABLE covid_silver_db.cases_standardized;



CREATE EXTERNAL TABLE IF NOT EXISTS covid_silver_db.testing_standardized (
    full_date       DATE,
    tests_total_cum BIGINT,
    tests_pos_cum   BIGINT,
    tests_neg_cum   BIGINT
)
PARTITIONED BY (
    state_code STRING,
    year       INT,
    month      INT,
    day        INT
)
STORED AS PARQUET
LOCATION 's3://covid-19-analytics-avishek/covid/silver/testing_standardized/';

MSCK REPAIR TABLE covid_silver_db.testing_standardized;


-- ------------------------------------------------------------
-- Quick validation
-- ------------------------------------------------------------

SELECT COUNT(*) AS cases_rows
FROM covid_silver_db.cases_standardized;

SELECT COUNT(*) AS testing_rows
FROM covid_silver_db.testing_standardized;

SELECT *
FROM covid_silver_db.cases_standardized
LIMIT 10;

SELECT *
FROM covid_silver_db.testing_standardized
LIMIT 10;
