-- WITH clause to create temporary tables for the latest batch dates for items, transactions, and people

-- Get the most recent batch date for each item from the item table
WITH item_batch AS (
  SELECT 
    item_id, 
    -- For each item, find the latest batch_date (converted to a date)
    MAX(DATE(batch_date)) AS latest_batch_date
  FROM `standard_nmr_feed_item_table`
  GROUP BY item_id
),
-- Get the most recent batch date for each transaction date from the fact table
trans_batch AS (
  SELECT 
    transaction_date, 
    -- For each transaction date, find the latest batch_date (converted to a date)
    MAX(DATE(batch_date)) AS latest_batch_date
  FROM `standard_nmr_feed_fact_table`
  GROUP BY transaction_date
),
-- Get the most recent batch date for each user from the people table
people_batch AS (
  SELECT 
    user_id, 
    -- For each user, find the latest batch_date (converted to a date)
    MAX(DATE(batch_date)) AS latest_batch_date
  FROM `standard_nmr_feed_people_table`
  GROUP BY user_id
)

SELECT 
  t.transaction_date, 
  p.gender_app_user, 
  p.age_bucket, 
  SUM(t.item_quantity) AS units_sold
FROM `standard_nmr_feed_item_table` i
-- Join the fact table to link items with their transaction details using item_id
JOIN `standard_nmr_feed_fact_table` t
  ON i.item_id = t.item_id
-- Join the people table to attach user details (like gender and age bucket) using user_id from the fact table
JOIN `standard_nmr_feed_people_table` p
  ON p.user_id = t.user_id
-- Join the item_batch CTE to ensure we only use the latest batch data for each item
JOIN item_batch ib
  ON i.item_id = ib.item_id
  AND DATE(i.batch_date) = ib.latest_batch_date
-- Join the trans_batch CTE to ensure we only use the latest batch data for each transaction date
JOIN trans_batch tb 
  ON t.transaction_date = tb.transaction_date
  AND DATE(t.batch_date) = tb.latest_batch_date
-- Join the people_batch CTE to ensure we only use the latest batch data for each user
JOIN people_batch pb
  ON p.user_id = pb.user_id
  AND DATE(p.batch_date) = pb.latest_batch_date
WHERE 
  -- Filter to include only items that belong to the category 'isc_hea_vit_min_collagen'
  i.category_id = 'isc_hea_vit_min_collagen'
-- Group the results by transaction date, gender, and age bucket to sum the units sold
GROUP BY 1, 2, 3;
