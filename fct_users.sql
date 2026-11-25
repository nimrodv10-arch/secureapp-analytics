{{ config(materialized='table') }}

WITH pay AS (
  SELECT user_id, COUNT(*) AS payments, SUM(amount_usd) AS revenue_usd
  FROM {{ ref('stg_payments') }}
  GROUP BY user_id
)
SELECT
  u.*,
  DATE_TRUNC(u.signup_date, MONTH) AS cohort_month,
  IFNULL(p.payments, 0) AS payments,
  IFNULL(p.revenue_usd, 0) AS revenue_usd,
  u.cancel_date IS NOT NULL AS churned
FROM {{ ref('stg_users') }} u
LEFT JOIN pay p USING (user_id)
