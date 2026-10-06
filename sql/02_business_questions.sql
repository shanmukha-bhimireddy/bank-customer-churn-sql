-- Bank customer churn: business questions answered in SQL (DuckDB dialect)

-- Q1: What is the overall churn rate, and how much balance left with churned customers?
SELECT COUNT(*)                               AS customers,
       SUM(churned)                           AS churned_customers,
       ROUND(100.0 * AVG(churned), 1)         AS churn_rate_pct,
       ROUND(SUM(balance * churned) / 1e6, 1) AS churned_balance_musd
FROM customers;

-- Q2: Which country loses the most customers?
SELECT country,
       COUNT(*)                               AS customers,
       ROUND(100.0 * AVG(churned), 1)         AS churn_rate_pct,
       ROUND(SUM(balance * churned) / 1e6, 1) AS churned_balance_musd
FROM customers
GROUP BY country
ORDER BY churn_rate_pct DESC;

-- Q3: How does churn vary by age band?
SELECT CASE WHEN age < 30 THEN '18-29'
            WHEN age < 40 THEN '30-39'
            WHEN age < 50 THEN '40-49'
            WHEN age < 60 THEN '50-59'
            ELSE '60+' END                    AS age_band,
       COUNT(*)                               AS customers,
       ROUND(100.0 * AVG(churned), 1)         AS churn_rate_pct
FROM customers
GROUP BY age_band
ORDER BY age_band;

-- Q4: Does holding more products reduce churn?
SELECT num_products,
       COUNT(*)                               AS customers,
       ROUND(100.0 * AVG(churned), 1)         AS churn_rate_pct
FROM customers
GROUP BY num_products
ORDER BY num_products;

-- Q5: Are inactive members more likely to leave?
SELECT CASE WHEN is_active THEN 'Active' ELSE 'Inactive' END AS member_status,
       COUNT(*)                               AS customers,
       ROUND(100.0 * AVG(churned), 1)         AS churn_rate_pct
FROM customers
GROUP BY member_status;

-- Q6: Do customers with money in the bank churn more or less than zero-balance customers?
SELECT CASE WHEN balance = 0 THEN 'Zero balance' ELSE 'Has balance' END AS balance_group,
       COUNT(*)                               AS customers,
       ROUND(AVG(balance), 0)                 AS avg_balance,
       ROUND(100.0 * AVG(churned), 1)         AS churn_rate_pct
FROM customers
GROUP BY balance_group;

-- Q7: Churn by credit score band
SELECT CASE WHEN credit_score < 580 THEN '1. Poor (<580)'
            WHEN credit_score < 670 THEN '2. Fair (580-669)'
            WHEN credit_score < 740 THEN '3. Good (670-739)'
            ELSE '4. Very good+ (740+)' END   AS score_band,
       COUNT(*)                               AS customers,
       ROUND(100.0 * AVG(churned), 1)         AS churn_rate_pct
FROM customers
GROUP BY score_band
ORDER BY score_band;

-- Q8: Churn by gender within each country
SELECT country, gender,
       COUNT(*)                               AS customers,
       ROUND(100.0 * AVG(churned), 1)         AS churn_rate_pct
FROM customers
GROUP BY country, gender
ORDER BY country, gender;

-- Q9: High-value customers (balance >= $100k): churn rate and money at risk
SELECT CASE WHEN balance >= 100000 THEN 'High value (>=100k)' ELSE 'Other' END AS value_tier,
       COUNT(*)                               AS customers,
       ROUND(100.0 * AVG(churned), 1)         AS churn_rate_pct,
       ROUND(SUM(balance * churned) / 1e6, 1) AS churned_balance_musd,
       ROUND(100.0 * SUM(balance * churned) / SUM(SUM(balance * churned)) OVER (), 1) AS share_of_lost_balance_pct
FROM customers
GROUP BY value_tier;

-- Q10: Top 5 riskiest segments (country x age band), minimum 200 customers — window function ranking
WITH seg AS (
    SELECT country,
           CASE WHEN age < 30 THEN '18-29' WHEN age < 40 THEN '30-39'
                WHEN age < 50 THEN '40-49' WHEN age < 60 THEN '50-59' ELSE '60+' END AS age_band,
           COUNT(*)                           AS customers,
           AVG(churned)                       AS churn_rate
    FROM customers
    GROUP BY 1, 2
    HAVING COUNT(*) >= 200
)
SELECT country, age_band, customers,
       ROUND(100.0 * churn_rate, 1)           AS churn_rate_pct,
       RANK() OVER (ORDER BY churn_rate DESC) AS risk_rank
FROM seg
QUALIFY risk_rank <= 5
ORDER BY risk_rank;

-- Q11: Tenure — do newer customers leave faster?
SELECT tenure_years,
       COUNT(*)                               AS customers,
       ROUND(100.0 * AVG(churned), 1)         AS churn_rate_pct
FROM customers
GROUP BY tenure_years
ORDER BY tenure_years;

-- Q12: Retention target list — a rule-based "high risk" flag and how well it concentrates churn
WITH flagged AS (
    SELECT *,
           (age BETWEEN 45 AND 65 AND NOT is_active)
           OR num_products >= 3                AS high_risk
    FROM customers
)
SELECT CASE WHEN high_risk THEN 'High risk' ELSE 'Standard' END AS risk_flag,
       COUNT(*)                               AS customers,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS share_of_customers_pct,
       SUM(churned)                           AS churned,
       ROUND(100.0 * SUM(churned) / SUM(SUM(churned)) OVER (), 1) AS share_of_churn_pct,
       ROUND(100.0 * AVG(churned), 1)         AS churn_rate_pct
FROM flagged
GROUP BY risk_flag
ORDER BY risk_flag;
