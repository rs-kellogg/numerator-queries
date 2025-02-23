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
) 
SELECT 
  DATE(t.transaction_date) AS transaction_date, 
  AVG(t.item_unit_price) as avg_price,
  STDDEV(t.item_unit_price) as std_price,
  APPROX_QUANTILES(t.item_unit_price, 100)[OFFSET(24)] as lq_price,
  APPROX_QUANTILES(t.item_unit_price, 100)[OFFSET(49)] AS median_price,
  APPROX_QUANTILES(t.item_unit_price, 100)[OFFSET(74)] AS uq_price
FROM `standard_nmr_feed_fact_table` AS t
JOIN trans_batch AS tb
ON t.transaction_date = tb.transaction_date
AND DATE(t.batch_date) = tb.latest_batch_date
JOIN `standard_nmr_feed_item_table` i
ON i.item_id = t.item_id
JOIN item_batch ib
ON i.item_id = ib.item_id
AND DATE(i.batch_date) = ib.latest_batch_date  
WHERE i.category_id = 'isc_gro_dai_egg_cage_free'
AND i.item_description like '%12%'
GROUP BY transaction_date
