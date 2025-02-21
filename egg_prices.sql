WITH items AS (
  SELECT item_id, batch_date
  FROM `standard_nmr_feed_item_table`
  WHERE majorcat_id = 'isc_gro_dai_eggs'
  AND category_id = 'isc_gro_dai_egg_cage_free'
  AND item_description like '%12%'
), prices as (
  SELECT 
    trans.transaction_date, trans.item_unit_price
  FROM `standard_nmr_feed_fact_table` trans
  JOIN items
  ON items.item_id = trans.item_id
  AND items.batch_date = trans.batch_date
  WHERE (
    items.batch_date = '2024-05-13' AND
    EXTRACT(YEAR from DATE(trans.transaction_date)) < 2024
  ) OR
  (
    items.batch_date = '2024-10-21' AND
    EXTRACT(Year FROM DATE(trans.transaction_date)) >= 2024
  )
)
SELECT 
  transaction_date,
  AVG(item_unit_price) as avg_price,
  STDDEV(item_unit_price) as std_price,
  APPROX_QUANTILES(item_unit_price, 100)[OFFSET(24)] as lq_price,
  APPROX_QUANTILES(item_unit_price, 100)[OFFSET(49)] AS median_price,
  APPROX_QUANTILES(item_unit_price, 100)[OFFSET(74)] AS uq_price
FROM prices
GROUP BY transaction_date
