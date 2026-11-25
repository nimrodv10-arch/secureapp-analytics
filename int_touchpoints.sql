{{ config(materialized='table') }}

SELECT
  t.user_id,
  t.channel,
  t.touch_ts,
  u.is_paid,
  ROW_NUMBER() OVER (PARTITION BY t.user_id ORDER BY t.touch_ts) AS touch_n,
  COUNT(*) OVER (PARTITION BY t.user_id) AS touches
FROM {{ ref('stg_touchpoints') }} t
JOIN {{ ref('stg_users') }} u USING (user_id)
WHERE t.touch_ts <= u.signup_ts
