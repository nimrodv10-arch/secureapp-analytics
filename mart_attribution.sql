{{ config(materialized='table') }}

WITH w AS (
  SELECT
    channel,
    IF(touch_n = touches, 1, 0) AS last_click,
    IF(touch_n = 1, 1, 0) AS first_click,
    1 / touches AS linear,
    CASE
      WHEN touches = 1 THEN 1
      WHEN touches = 2 THEN 0.5
      WHEN touch_n IN (1, touches) THEN 0.4
      ELSE 0.2 / (touches - 2)
    END AS position_based
  FROM {{ ref('int_touchpoints') }}
  WHERE is_paid
),
credit AS (
  SELECT channel,
    SUM(last_click) AS last_click, SUM(first_click) AS first_click,
    SUM(linear) AS linear, SUM(position_based) AS position_based
  FROM w GROUP BY channel
),
spend AS (
  SELECT channel, SUM(spend_usd) AS spend_usd FROM {{ ref('stg_spend') }} GROUP BY channel
)
SELECT
  c.*,
  ROUND(SAFE_DIVIDE(s.spend_usd, c.last_click), 1) AS cac_last,
  ROUND(SAFE_DIVIDE(s.spend_usd, c.first_click), 1) AS cac_first,
  ROUND(SAFE_DIVIDE(s.spend_usd, c.linear), 1) AS cac_linear,
  ROUND(SAFE_DIVIDE(s.spend_usd, c.position_based), 1) AS cac_position
FROM credit c
LEFT JOIN spend s USING (channel)
ORDER BY last_click DESC
