-- ============================================================
-- Athena SQL: BI Analytics Queries
-- Project: COVID-19 Analytics AWS Pipeline
-- Notes:
--   - These queries run in Athena against covid_gold_db.
--   - The original project query used 20200515, but this dataset
--     ended at 20200509, so analytics queries use 20200509.
--   - Athena uses CAST(... AS DOUBLE), not Redshift/Postgres :: syntax.
-- ============================================================

-- ------------------------------------------------------------
-- 1. Check available date range
-- ------------------------------------------------------------

SELECT
    MIN(date_id) AS min_date,
    MAX(date_id) AS max_date
FROM covid_gold_db.fact_cases_state_daily;


-- ------------------------------------------------------------
-- 2. Top 5 states by new cases on 2020-05-09
-- ------------------------------------------------------------

SELECT
    s.state_name,
    f.new_cases
FROM covid_gold_db.fact_cases_state_daily f
JOIN covid_gold_db.dim_state s
    ON s.state_code = f.state_code
WHERE f.date_id = 20200509
ORDER BY f.new_cases DESC
LIMIT 5;


-- ------------------------------------------------------------
-- 3. Top 5 states by total cases on 2020-05-09
-- ------------------------------------------------------------

SELECT
    s.state_name,
    f.cases_cum
FROM covid_gold_db.fact_cases_state_daily f
JOIN covid_gold_db.dim_state s
    ON s.state_code = f.state_code
WHERE f.date_id = 20200509
ORDER BY f.cases_cum DESC
LIMIT 5;


-- ------------------------------------------------------------
-- 4. Top 5 states by total deaths on 2020-05-09
-- ------------------------------------------------------------

SELECT
    s.state_name,
    f.deaths_cum
FROM covid_gold_db.fact_cases_state_daily f
JOIN covid_gold_db.dim_state s
    ON s.state_code = f.state_code
WHERE f.date_id = 20200509
ORDER BY f.deaths_cum DESC
LIMIT 5;


-- ------------------------------------------------------------
-- 5. Positivity rate trend for New York
-- ------------------------------------------------------------

SELECT
    d.full_date,
    CAST(t.tests_pos_cum AS DOUBLE) / NULLIF(t.tests_total_cum, 0) AS positivity_rate
FROM covid_gold_db.fact_testing_state_daily t
JOIN covid_gold_db.dim_date d
    ON d.date_id = t.date_id
WHERE t.state_code = 'NY'
ORDER BY d.full_date;


-- ------------------------------------------------------------
-- 6. Daily cases vs tests for California
-- ------------------------------------------------------------

SELECT
    d.full_date,
    c.new_cases,
    t.new_tests,
    CAST(t.tests_pos_cum AS DOUBLE) / NULLIF(t.tests_total_cum, 0) AS positivity_rate
FROM covid_gold_db.fact_cases_state_daily c
JOIN covid_gold_db.fact_testing_state_daily t
    ON t.date_id = c.date_id
   AND t.state_code = c.state_code
JOIN covid_gold_db.dim_date d
    ON d.date_id = c.date_id
WHERE c.state_code = 'CA'
ORDER BY d.full_date;


-- ------------------------------------------------------------
-- 7. Highest daily positivity-rate records
-- ------------------------------------------------------------

SELECT
    s.state_name,
    t.positivity_rate
FROM covid_gold_db.fact_testing_state_daily t
JOIN covid_gold_db.dim_state s
    ON s.state_code = t.state_code
ORDER BY t.positivity_rate DESC
LIMIT 10;
