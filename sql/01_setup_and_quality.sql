-- Setup: load the CSV into a typed table (DuckDB)
CREATE OR REPLACE TABLE customers AS
SELECT CustomerId        AS customer_id,
       CreditScore       AS credit_score,
       Geography         AS country,
       Gender            AS gender,
       Age               AS age,
       Tenure            AS tenure_years,
       Balance           AS balance,
       NumOfProducts     AS num_products,
       HasCrCard::BOOLEAN       AS has_credit_card,
       IsActiveMember::BOOLEAN  AS is_active,
       EstimatedSalary   AS est_salary,
       Exited            AS churned
FROM read_csv_auto('data/Churn_Modelling.csv');

-- Q: Data quality — row count, duplicates and nulls
SELECT COUNT(*)                                   AS rows_loaded,
       COUNT(DISTINCT customer_id)                AS unique_customers,
       COUNT(*) - COUNT(DISTINCT customer_id)     AS duplicate_ids,
       SUM(CASE WHEN credit_score IS NULL OR age IS NULL OR balance IS NULL THEN 1 ELSE 0 END) AS rows_with_nulls,
       MIN(age) AS min_age, MAX(age) AS max_age,
       MIN(credit_score) AS min_score, MAX(credit_score) AS max_score
FROM customers;
