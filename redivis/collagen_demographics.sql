WITH item_batch AS (
  SELECT 
    item_id, 
    MAX(DATE(batch_date)) AS latest_batch_date
  FROM `standard_nmr_feed_item_table`
  GROUP BY item_id
), trans_batch AS (
  SELECT transaction_date, MAX(DATE(batch_date)) as latest_batch_date
  FROM `standard_nmr_feed_fact_table`
  GROUP BY transaction_date
), people_batch AS (
  SELECT 
    user_id, 
    MAX(DATE(batch_date)) AS latest_batch_date
  FROM `standard_nmr_feed_people_table`
  GROUP BY user_id
)
SELECT 
  t.transaction_date, 
  p.gender_app_user, 
  p.age_bucket, 
  SUM(t.item_quantity) as units_sold
FROM `standard_nmr_feed_item_table` i
JOIN `standard_nmr_feed_fact_table` t
ON i.item_id = t.item_id
JOIN `standard_nmr_feed_people_table` p
ON p.user_id = t.user_id
JOIN item_batch ib
ON i.item_id = ib.item_id
AND DATE(i.batch_date) = ib.latest_batch_date
JOIN trans_batch tb 
ON t.transaction_date = tb.transaction_date
AND DATE(t.batch_date) = tb.latest_batch_date
JOIN people_batch pb
ON p.user_id = pb.user_id
AND DATE(p.batch_date) = pb.latest_batch_date
WHERE i.category_id = 'isc_hea_vit_min_collagen'
GROUP BY 1, 2, 3