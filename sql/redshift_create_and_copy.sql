-- ============================================================
-- Redshift SQL: Create Tables and COPY Gold Data from S3
-- Project: COVID-19 Analytics AWS Pipeline


CREATE SCHEMA covid_gold;

CREATE TABLE covid_gold.dim_date (
    full_date  DATE,
    date_id    INT,
    year       INT,
    month      INT,
    day        INT,
    dow        INT,
    is_weekend BOOLEAN
);

COPY covid_gold.dim_date
FROM 's3://covid-19-analytics-avishek/covid/gold/dim_date/'
IAM_ROLE 'arn:aws:iam::<ACCOUNT_ID>:role/CovidRedshiftS3AccessRole'
FORMAT AS PARQUET
REGION 'us-east-1';

SELECT COUNT(*) AS dim_date_rows
FROM covid_gold.dim_date;


CREATE TABLE covid_gold.dim_state (
    state_code VARCHAR(2),
    state_name VARCHAR(64)
);

COPY covid_gold.dim_state
FROM 's3://covid-19-analytics-avishek/covid/gold/dim_state/'
IAM_ROLE 'arn:aws:iam::<ACCOUNT_ID>:role/CovidRedshiftS3AccessRole'
FORMAT AS PARQUET
REGION 'us-east-1';

SELECT COUNT(*) AS dim_state_rows
FROM covid_gold.dim_state;


-- ------------------------------------------------------------
--  Fact Table: fact_cases_state_daily
--
-- Important:
--   In the S3 Gold layer, this table was partitioned by state_code.
--   Athena can read state_code from Glue partition metadata.
--   Redshift COPY expects physical Parquet columns.
--   Therefore this load-validation table matches the physical Parquet schema.
-- ------------------------------------------------------------

CREATE TABLE covid_gold.fact_cases_state_daily (
    date_id    INT,
    cases_cum  BIGINT,
    deaths_cum BIGINT,
    new_cases  BIGINT,
    new_deaths BIGINT
);

COPY covid_gold.fact_cases_state_daily
FROM 's3://covid-19-analytics-avishek/covid/gold/fact_cases_state_daily/'
IAM_ROLE 'arn:aws:iam::<ACCOUNT_ID>:role/CovidRedshiftS3AccessRole'
FORMAT AS PARQUET
REGION 'us-east-1';

SELECT COUNT(*) AS fact_cases_rows
FROM covid_gold.fact_cases_state_daily;


-- ------------------------------------------------------------
--  Fact Table: fact_testing_state_daily
--
-- Important:
--   In the S3 Gold layer, this table was partitioned by state_code.
--   This Redshift table matches the physical Parquet schema for COPY.
-- ------------------------------------------------------------

CREATE TABLE covid_gold.fact_testing_state_daily (
    date_id         INT,
    tests_total_cum BIGINT,
    tests_pos_cum   BIGINT,
    tests_neg_cum   BIGINT,
    new_tests       BIGINT,
    positivity_rate DOUBLE PRECISION
);

COPY covid_gold.fact_testing_state_daily
FROM 's3://covid-19-analytics-avishek/covid/gold/fact_testing_state_daily/'
IAM_ROLE 'arn:aws:iam::<ACCOUNT_ID>:role/CovidRedshiftS3AccessRole'
FORMAT AS PARQUET
REGION 'us-east-1';

SELECT COUNT(*) AS fact_testing_rows
FROM covid_gold.fact_testing_state_daily;


-- ------------------------------------------------------------
-- Analyze Tables
-- ------------------------------------------------------------

ANALYZE VERBOSE;




SELECT 'dim_date' AS table_name, COUNT(*) AS row_count
FROM covid_gold.dim_date
UNION ALL
SELECT 'dim_state' AS table_name, COUNT(*) AS row_count
FROM covid_gold.dim_state
UNION ALL
SELECT 'fact_cases_state_daily' AS table_name, COUNT(*) AS row_count
FROM covid_gold.fact_cases_state_daily
UNION ALL
SELECT 'fact_testing_state_daily' AS table_name, COUNT(*) AS row_count
FROM covid_gold.fact_testing_state_daily;
