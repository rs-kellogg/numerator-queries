/* 
In each new batch, only new items and changed items are appended (i.e., the description changes slightly).
You should select the record in the item table corresponding to the latest batch date for that item ID
*/
WITH item_batch AS (
  SELECT 
    item_id, 
    MAX(DATE(batch_date)) AS latest_batch_date
  FROM `standard_nmr_feed_item_table`
  GROUP BY item_id
) 
SELECT t.* 
FROM `standard_nmr_feed_item_table` t
JOIN item_batch b
ON  b.item_id = t.item_id
AND b.latest_batch_date = DATE(t.batch_date);

/*
Many of the batches contain multiple quarters worth of transactions (repeats included),
so you should choose the latest batch date for that transaction date
*/
WITH fact_batch AS (
  SELECT transaction_date, MAX(DATE(batch_date)) as latest_batch_date
  FROM `standard_nmr_feed_fact_table`
  GROUP BY transaction_date
)
SELECT t.*
FROM `standard_nmr_feed_fact_table` t
JOIN fact_batch b
ON b.transaction_date = t.transaction_date
AND b.latest_batch_date = DATE(t.batch_date);

/*
We expect the demographic information of each individual person to naturally change over time -
people get older, have kids, change their income, move, get married/divorced, etc. However, 
Numerator will create new user IDs when people move in and out of demographics. It will only duplicate
user IDs in new batches when information has been updated. Therefore, you should select the latest
batch date for that user ID.
*/
WITH people_batch AS (
  SELECT 
    user_id, 
    MAX(DATE(batch_date)) AS latest_batch_date
  FROM `standard_nmr_feed_people_table`
  GROUP BY user_id
) 
SELECT p.* 
FROM `standard_nmr_feed_people_table` p
JOIN people_batch b
ON  b.user_id = p.user_id
AND b.latest_batch_date = DATE(p.batch_date);