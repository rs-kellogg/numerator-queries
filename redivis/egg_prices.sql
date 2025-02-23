-- WITH clause to precompute the latest batch date for each item from the item table
WITH item_batch AS (
  SELECT 
    item_id, 
    -- For each item, find the latest batch date (converted to date only)
    MAX(DATE(batch_date)) AS latest_batch_date
  FROM `standard_nmr_feed_item_table`
  GROUP BY item_id
),
-- WITH clause to precompute the latest batch date for each transaction date from the fact table
trans_batch AS (
  SELECT 
    transaction_date, 
    -- For each transaction date, find the latest batch date (converted to date only)
    MAX(DATE(batch_date)) as latest_batch_date
  FROM `standard_nmr_feed_fact_table`
  GROUP BY transaction_date
) 
SELECT 
  -- Convert the transaction_date to date format
  DATE(t.transaction_date) AS transaction_date, 
  AVG(t.item_unit_price) as avg_price,
  STDDEV(t.item_unit_price) as std_price,
  -- Calculate lower quartile price using approx quantiles
  APPROX_QUANTILES(t.item_unit_price, 100)[OFFSET(24)] as lq_price,
  -- Calculate median price using approx quantiles
  APPROX_QUANTILES(t.item_unit_price, 100)[OFFSET(49)] AS median_price,
  -- Calculate upper quartile price using approx quantiles
  APPROX_QUANTILES(t.item_unit_price, 100)[OFFSET(74)] AS uq_price
FROM `standard_nmr_feed_fact_table` AS t
-- Join to ensure we're using the latest batch date for each transaction date
JOIN trans_batch AS tb
  ON t.transaction_date = tb.transaction_date
  -- Only include fact table rows where the batch_date matches the latest batch date for that transaction_date
  AND DATE(t.batch_date) = tb.latest_batch_date
-- Join the item table to add item details for each fact record
JOIN `standard_nmr_feed_item_table` i
  ON i.item_id = t.item_id
-- Join to ensure we're using the latest batch date for each item record
JOIN item_batch ib
  ON i.item_id = ib.item_id
  -- Only include item table rows where the batch_date matches the latest batch date for that item
  AND DATE(i.batch_date) = ib.latest_batch_date  
WHERE 
  -- Filter to include only items belonging to the specific category 'isc_gro_dai_egg_cage_free'
  i.category_id = 'isc_gro_dai_egg_cage_free'
  -- Filter to include only items with '12' in the description
  AND i.item_description like '%12%'
-- Group results by transaction_date to calculate the aggregated statistics per day
GROUP BY transaction_date;
