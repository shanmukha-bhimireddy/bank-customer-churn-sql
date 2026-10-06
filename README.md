# Bank Customer Churn — SQL Case Study

Using SQL to answer the questions a retail bank's leadership would ask about customer attrition: **who is leaving, how much money leaves with them, and where should the retention team focus?**

**Tools:** SQL (DuckDB — CTEs, window functions, `QUALIFY`, conditional aggregation) · Python runner

## Data
10,000 customers of a European retail bank ([`data/Churn_Modelling.csv`](data/Churn_Modelling.csv), public "Bank Customer Churn" dataset widely used for analytics practice). Fields include country, age, tenure, balance, number of products, activity status and whether the customer left (`Exited`).

Data quality check (`sql/01_setup_and_quality.sql`): 10,000 rows, 0 duplicate IDs, 0 nulls.

## Questions answered
| # | Business question | SQL techniques |
|---|---|---|
| 1 | Overall churn rate and balance lost | aggregation |
| 2 | Churn by country | `GROUP BY`, sorting |
| 3 | Churn by age band | `CASE` bucketing |
| 4 | Does product holding reduce churn? | aggregation |
| 5 | Active vs. inactive members | `CASE`, aggregation |
| 6 | Zero-balance vs. funded accounts | conditional grouping |
| 7 | Churn by credit score band | `CASE` bucketing |
| 8 | Gender × country | multi-level grouping |
| 9 | High-value customers and share of balance lost | window function over aggregate |
| 10 | Top 5 riskiest segments | CTE, `RANK()`, `QUALIFY` |
| 11 | Tenure effect | aggregation |
| 12 | Rule-based retention target list | CTE, share-of-total windows |

Queries: [`sql/02_business_questions.sql`](sql/02_business_questions.sql) · All outputs: [`results/query_results.md`](results/query_results.md)

## Key findings
- **1 in 5 customers left (20.4%)**, taking **$185.6M** in balances with them.
- **Germany is the problem market:** churn of **32.4%**, double France (16.2%) and Spain (16.7%), and **$98M** of lost balances — more than half the total.
- **Age is the strongest signal:** churn rises from 7.6% (18–29) to **56% for customers aged 50–59**. German customers aged 50–59 churn at **70%**.
- **Product count matters, in both directions:** customers with 2 products churn at only **7.6%**, but those with 3–4 products churn at **83–100%** — a sign of mis-sold or bundled products that disappoint.
- **Inactive members churn nearly 2× more** (26.9% vs. 14.3%).
- **High-value customers (≥$100k balance) churn more (25.2%)** and account for **86% of lost balances**.
- Tenure and credit score show **little effect** — useful to know where *not* to spend retention budget.

## Recommendation
A simple rule — *(age 45–65 and inactive) or 3+ products* — flags **12% of customers who account for 42% of all churn** (70% churn rate in the flagged group). That gives the retention team a short, high-yield call list:
1. Prioritise **German customers aged 40–59**, especially high-balance accounts.
2. Re-engage inactive members before they leave (outreach, digital nudges).
3. Review cross-selling into 3+ products — it appears to drive churn, not loyalty.
4. Encourage the move from 1 to 2 products, the "sweet spot" for retention.

Interactive version: [Bank Retention Dashboard](https://shanmukha-bhimireddy.github.io/bank-retention-dashboard/)

## Run it
```bash
pip install -r requirements.txt
python scripts/run_queries.py      # writes results/query_results.md
# or interactively:
duckdb -c ".read sql/01_setup_and_quality.sql" -c ".read sql/02_business_questions.sql"
```

---
*Built by Shanmukha Sai Reddy Bhimireddy — Data / Business Analyst. Public data only.*
