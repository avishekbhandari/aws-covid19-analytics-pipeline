# AWS COVID-19 Analytics Pipeline

## Project Overview

This project is an AWS-based COVID-19 analytics pipeline. I built it to practice a realistic cloud data engineering workflow using Amazon S3, AWS Glue ETL, Athena, AWS Glue Data Catalog, Redshift Serverless, PySpark, SQL, and Parquet.

The project takes raw COVID-19 datasets, stores them in an S3 data lake, transforms the data into cleaned Silver datasets, builds Gold fact and dimension tables, validates the final data in Athena, and loads the Gold layer into Redshift Serverless for warehouse validation.

---

## What This Project Shows

This project demonstrates:

- organizing raw, cleaned, and analytics-ready data in S3
- building Bronze, Silver, and Gold data lake layers
- using AWS Glue ETL jobs with PySpark
- converting raw CSV files into Parquet
- creating partitioned datasets for Athena queries
- creating Athena external tables with SQL
- using AWS Glue Data Catalog metadata
- building simple fact and dimension tables
- running BI-style analytics queries in Athena
- loading Gold Parquet data into Redshift Serverless
- debugging schema and partition behavior between Athena and Redshift

---

## Architecture

```text
Raw CSV Files
        ↓
Amazon S3 Bronze Layer
        ↓
AWS Glue ETL Job: Bronze to Silver
        ↓
Amazon S3 Silver Layer
        ↓
Athena External Tables
        ↓
AWS Glue Data Catalog
        ↓
AWS Glue ETL Job: Silver to Gold
        ↓
Amazon S3 Gold Layer
        ↓
Athena External Tables
        ↓
Athena BI Analytics Queries
        ↓
Redshift Serverless COPY Load Validation
```

---

## AWS Services and Tools Used

| Service / Tool | Purpose |
|---|---|
| Amazon S3 | Stored Bronze, Silver, and Gold data lake layers |
| AWS Glue ETL | Ran PySpark transformation jobs |
| AWS Glue Data Catalog | Stored external table metadata |
| Amazon Athena | Queried S3 Parquet data using SQL |
| Amazon Redshift Serverless | Loaded Gold data for warehouse validation |
| AWS IAM | Managed access between Glue, Redshift, and S3 |
| PySpark | Performed transformations and business logic |
| SQL | Created external tables, validation checks, and analytics queries |
| Parquet | Stored Silver and Gold data in an analytics-friendly format |

---

## Source Data

The project uses three CSV files:

| File | Purpose |
|---|---|
| `us_states.csv` | COVID cases and deaths by state/date |
| `states_daily.csv` | COVID testing metrics by state/date |
| `states_abv.csv` | State name and abbreviation lookup |

In S3, these files were uploaded to the Bronze layer:

```text
covid/bronze/nytimes/us_states.csv
covid/bronze/covid_tracking/states_daily.csv
covid/bronze/static/states_abv.csv
```

---

## Data Lake Layers

### Bronze Layer

The Bronze layer stores the original raw CSV files.

```text
covid/bronze/
├── nytimes/
├── covid_tracking/
└── static/
```

### Silver Layer

The Silver layer stores cleaned and standardized Parquet data.

```text
covid/silver/
├── cases_standardized/
└── testing_standardized/
```

The Silver tables include standardized fields such as:

```text
full_date
state_code
state_name
cases_cum
deaths_cum
tests_total_cum
tests_pos_cum
tests_neg_cum
year
month
day
```

### Gold Layer

The Gold layer stores analytics-ready dimension and fact tables.

```text
covid/gold/
├── dim_date/
├── dim_state/
├── fact_cases_state_daily/
└── fact_testing_state_daily/
```

---

## Glue ETL Jobs

### Bronze to Silver

The first Glue job reads the raw Bronze CSV files, standardizes the data, casts numeric columns, creates date and partition fields, and writes the Silver output as Parquet.

Main output folders:

```text
covid/silver/cases_standardized/
covid/silver/testing_standardized/
```

Main transformations:

- converted date fields into `full_date`
- standardized state names and state codes
- cast case, death, and testing metrics into numeric fields
- created partition columns: `state_code`, `year`, `month`, `day`
- wrote output as partitioned Parquet

The exported Glue job configuration is included here:

```text
scripts/covid-bronze-to-silver.json
```

### Silver to Gold

The second Glue job reads the Silver Parquet datasets and creates Gold fact and dimension tables.

Gold tables created:

```text
dim_date
dim_state
fact_cases_state_daily
fact_testing_state_daily
```

The job also calculates daily metrics from cumulative values:

```text
new_cases = current_day_cases_cum - previous_day_cases_cum
new_deaths = current_day_deaths_cum - previous_day_deaths_cum
new_tests = current_day_tests_total_cum - previous_day_tests_total_cum
positivity_rate = tests_pos_cum / tests_total_cum
```

The exported Glue job configuration is included here:

```text
scripts/covid-silver-to-gold.json
```

---

## Athena Tables

Athena external tables were created manually using SQL. The table metadata is stored in the AWS Glue Data Catalog.

SQL files included:

```text
sql/athena_create_silver_tables.sql
sql/athena_create_gold_tables.sql
sql/athena_bi_analytics_queries.sql
```

### Silver Athena Tables

```text
covid_silver_db.cases_standardized
covid_silver_db.testing_standardized
```

### Gold Athena Tables

```text
covid_gold_db.dim_date
covid_gold_db.dim_state
covid_gold_db.fact_cases_state_daily
covid_gold_db.fact_testing_state_daily
```

Partition repair was run with `MSCK REPAIR TABLE` so Athena could recognize partitioned folders in S3.

---

## Redshift Serverless Validation

The Gold Parquet data was also loaded into Redshift Serverless for warehouse validation.

The Redshift SQL file is included here:

```text
sql/redshift_create_and_copy.sql
```

This file contains:

- Redshift schema creation
- target table creation
- `COPY` commands from S3 Gold Parquet folders
- row count validation queries
- `ANALYZE VERBOSE`

One important learning point from this part was that Athena and Redshift can read the same S3 Parquet data differently. Athena can use Glue partition metadata, while Redshift COPY expects the physical Parquet schema to match the target table more directly.

---

## Analytics Queries

Final analytics queries were run in Athena against the Gold layer.

The included BI query file contains:

```text
sql/athena_bi_analytics_queries.sql
```

Example analytics completed:

- check available date range
- top 5 states by new cases
- top 5 states by total cases
- top 5 states by total deaths
- positivity rate trend for New York
- daily cases vs tests for California
- highest positivity-rate records

The dataset used in this project went up to `20200509`, so final date-based analytics used that date.

Example result for top states by new cases on `20200509`:

| State | New Cases |
|---|---:|
| New York | 2715 |
| Illinois | 2320 |
| California | 2208 |
| New Jersey | 1631 |
| Massachusetts | 1410 |

---

## Repository Structure

```text
aws-covid19-analytics-pipeline/
│
├── data/
│   ├── states_abv.csv
│   ├── states_daily.csv
│   └── us_states.csv
│
├── docs/
│   └── project_steps.md
│
├── screenshots/
│   ├── 01_s3_covid_root_folders.png
│   ├── 02_s3_bronze_folders.png
│   ├── ...
│   └── 26_athena_daily_cases_vs_tests_ca.png
│
├── scripts/
│   ├── covid-bronze-to-silver.json
│   └── covid-silver-to-gold.json
│
├── sql/
│   ├── athena_create_silver_tables.sql
│   ├── athena_create_gold_tables.sql
│   ├── athena_bi_analytics_queries.sql
│   └── redshift_create_and_copy.sql
│
├── README.md
├── requirements.txt
└── .gitignore
```

---

## Screenshots

The `screenshots/` folder contains AWS execution proof, including:

- S3 Bronze/Silver/Gold folders
- uploaded raw datasets
- Glue IAM role
- Glue Bronze-to-Silver job
- Glue Silver-to-Gold job
- Silver and Gold Parquet output folders
- Athena external table creation
- Glue Data Catalog tables
- Redshift Serverless setup
- Redshift schema/COPY editor
- Athena BI query outputs

---

## Project Documentation

A detailed step-by-step explanation is available here:

```text
docs/project_steps.md
```

This file explains how the project was built, what each AWS service was used for, what validations were completed, and what issues were found during Redshift loading.

---

## Key Lessons Learned

- S3 folder structure is important when building a data lake.
- Parquet is better than CSV for analytics workloads.
- Partitioning helps Athena query data more efficiently.
- Athena external tables depend on Glue Data Catalog metadata.
- Glue ETL is useful for transforming raw CSV into standardized Parquet.
- A Gold layer with dimensions and facts makes analytics queries easier.
- Athena and Redshift may handle partitioned Parquet data differently.
- Clear documentation and screenshots make cloud projects easier to explain.

---
