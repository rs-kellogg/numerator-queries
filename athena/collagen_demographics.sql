WITH item_batch AS (
  SELECT 
    item_id, 
    MAX(date_parse(batch_date, '%m%d%Y')) AS latest_batch_date
  FROM standard_nmr_feed_item_table
  GROUP BY item_id
),
trans_batch AS (
  SELECT 
    transaction_date, 
    MAX(date_parse(batch_date, '%m%d%Y')) AS latest_batch_date
  FROM standard_nmr_feed_fact_table
  GROUP BY transaction_date
),
people_batch AS (
  SELECT 
    user_id, 
    MAX(date_parse(batch_date, '%m%d%Y')) AS latest_batch_date
  FROM standard_nmr_feed_people_table
  GROUP BY user_id
)

SELECT 
  t.transaction_date, 
  p.gender_app_user, 
  p.age_bucket, 
  SUM(t.item_quantity) AS units_sold
FROM standard_nmr_feed_item_table i
JOIN standard_nmr_feed_fact_table t
  ON i.item_id = t.item_id
JOIN standard_nmr_feed_people_table p
  ON p.user_id = t.user_id
JOIN item_batch ib
  ON i.item_id = ib.item_id
  AND date_parse(i.batch_date, '%m%d%Y') = ib.latest_batch_date
JOIN trans_batch tb 
  ON t.transaction_date = tb.transaction_date
  AND date_parse(t.batch_date, '%m%d%Y') = tb.latest_batch_date
JOIN people_batch pb
  ON p.user_id = pb.user_id
  AND date_parse(p.batch_date, '%m%d%Y') = pb.latest_batch_date
WHERE 
  i.category_id = 'isc_hea_vit_min_collagen'
GROUP BY 
  t.transaction_date, 
  p.gender_app_user, 
  p.age_bucket;
