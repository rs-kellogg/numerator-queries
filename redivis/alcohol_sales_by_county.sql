WITH poly AS (
  SELECT 
    c.geometry AS county_borders, 
    c.name as county_name, 
    s.name as state_name
  FROM `demo.us_political_boundaries.us_counties` c
  JOIN `demo.us_political_boundaries.us_states` s
  ON s.state = c.state
  WHERE (
    (s.name = 'Illinois' and c.name = 'St. Clair') OR
    (s.name = 'Missouri' and c.name = 'St. Louis'))
  AND c.lsad = 'County'
), bbox AS (
SELECT 
  MIN(ST_BOUNDINGBOX(county_borders)[OFFSET(0)]) AS long_min,
  MIN(ST_BOUNDINGBOX(county_borders)[OFFSET(1)]) AS lat_min,
  MAX(ST_BOUNDINGBOX(county_borders)[OFFSET(2)]) AS long_max,
  MAX(ST_BOUNDINGBOX(county_borders)[OFFSET(3)]) AS lat_max
  FROM poly
), item_batch AS (
  SELECT 
    item_id, 
    MAX(DATE(batch_date)) AS latest_batch_date
  FROM `kellogg.numerator.standard_nmr_feed_item_table`
  GROUP BY item_id
), trans_batch AS (
  SELECT transaction_date, MAX(DATE(batch_date)) as latest_batch_date
  FROM `kellogg.numerator.standard_nmr_feed_fact_table`
  GROUP BY transaction_date
), sales_bbox AS (
  SELECT 
    t.transaction_date, 
    ST_GEOGPOINT(t.longitude, t.latitude) AS trans_geopoint, 
    t.item_total
  FROM `kellogg.numerator.standard_nmr_feed_item_table` i
  JOIN `kellogg.numerator.standard_nmr_feed_fact_table` t
  ON i.item_id = t.item_id
  JOIN item_batch ib
  ON i.item_id = ib.item_id
  AND DATE(i.batch_date) = ib.latest_batch_date
  JOIN trans_batch tb
  ON t.transaction_date = tb.transaction_date
  AND DATE(t.batch_date) = tb.latest_batch_date
  JOIN bbox
  ON t.latitude BETWEEN bbox.lat_min AND bbox.lat_max
  AND t.longitude BETWEEN bbox.long_min AND bbox.long_max
  WHERE i.dept_id = 'isc_gro_bev_beer_wine_and_spirits'
  AND EXTRACT(YEAR FROM DATE(t.transaction_date)) BETWEEN 2018 AND 2022
) SELECT 
    EXTRACT(YEAR FROM DATE(s.transaction_date)) AS trans_year,
    EXTRACT(MONTH FROM DATE(s.transaction_Date)) AS trans_month, 
    p.county_name,
    p.state_name,
    SUM(s.item_total) AS total_sales
  FROM sales_bbox s
  JOIN poly p
  ON ST_COVERS(ST_BUFFER(p.county_borders,2000),ST_BUFFER(s.trans_geopoint,2000))
  WHERE ST_CONTAINS(p.county_borders,s.trans_geopoint)
  GROUP BY 1, 2, 3, 4