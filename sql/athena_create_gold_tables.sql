-- ============================================================
-- Athena SQL: Create Gold External Tables
-- Project: COVID-19 Analytics AWS Pipeline
-- Notes:
--   - Gold tables are stored as Parquet in S3.
--   - Athena external table metadata is stored in AWS Glue Data Catalog.
--   - Fact tables are partitioned by state_code.
-- ============================================================

CREATE DATABASE IF NOT EXISTS covid_gold_db;


DROP TABLE IF EXISTS covid_gold_db.dim_date;

CREATE EXTERNAL TABLE IF NOT EXISTS covid_gold_db.dim_date (
    full_date  DATE,
    date_id    INT,
    year       INT,
    month      INT,
    day        INT,
    dow        INT,
    is_weekend BOOLEAN
)
STORED AS PARQUET
LOCATION 's3://covid-19-analytics-avishek/covid/gold/dim_date/';



DROP TABLE IF EXISTS covid_gold_db.dim_state;

CREATE EXTERNAL TABLE IF NOT EXISTS covid_gold_db.dim_state (
    state_code STRING,
    state_name STRING
)
STORED AS PARQUET
LOCATION 's3://covid-19-analytics-avishek/covid/gold/dim_state/';




DROP TABLE IF EXISTS covid_gold_db.fact_cases_state_daily;

CREATE EXTERNAL TABLE IF NOT EXISTS covid_gold_db.fact_cases_state_daily (
    date_id    INT,
    cases_cum  BIGINT,
    deaths_cum BIGINT,
    new_cases  BIGINT,
    new_deaths BIGINT
)
PARTITIONED BY (
    state_code STRING
)
STORED AS PARQUET
LOCATION 's3://covid-19-analytics-avishek/covid/gold/fact_cases_state_daily/';

MSCK REPAIR TABLE covid_gold_db.fact_cases_state_daily;



DROP TABLE IF EXISTS covid_gold_db.fact_testing_state_daily;

CREATE EXTERNAL TABLE IF NOT EXISTS covid_gold_db.fact_testing_state_daily (
    date_id         INT,
    tests_total_cum BIGINT,
    tests_pos_cum   BIGINT,
    tests_neg_cum   BIGINT,
    new_tests       BIGINT,
    positivity_rate DOUBLE
)
PARTITIONED BY (
    state_code STRING
)
STORED AS PARQUET
LOCATION 's3://covid-19-analytics-avishek/covid/gold/fact_testing_state_daily/';

MSCK REPAIR TABLE covid_gold_db.fact_testing_state_daily;


-- ------------------------------------------------------------
-- Quick validation
-- ------------------------------------------------------------

SELECT COUNT(*) AS dim_date_rows
FROM covid_gold_db.dim_date;

SELECT COUNT(*) AS dim_state_rows
FROM covid_gold_db.dim_state;

SELECT COUNT(*) AS fact_cases_rows
FROM covid_gold_db.fact_cases_state_daily;

SELECT COUNT(*) AS fact_testing_rows
FROM covid_gold_db.fact_testing_state_daily;

SELECT
    MIN(date_id) AS min_date,
    MAX(date_id) AS max_date
FROM covid_gold_db.fact_cases_state_daily;

SELECT *
FROM covid_gold_db.fact_cases_state_daily
LIMIT 10;
