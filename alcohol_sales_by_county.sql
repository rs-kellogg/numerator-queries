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
), sales_bbox AS (
  SELECT 
    f.transaction_date, 
    ST_GEOGPOINT(f.longitude, f.latitude) AS trans_geopoint, 
    f.item_total
  FROM `kellogg.numerator.standard_nmr_feed_item_table` i
  JOIN `kellogg.numerator.standard_nmr_feed_fact_table` f
  ON i.item_id = f.item_id
  AND i.batch_date = f.batch_date
  JOIN bbox
  ON f.latitude BETWEEN bbox.lat_min AND bbox.lat_max
  AND f.longitude BETWEEN bbox.long_min AND bbox.long_max
  WHERE dept_id = 'isc_gro_bev_beer_wine_and_spirits'
  AND i.batch_date = '2024-05-13'
  AND EXTRACT(YEAR FROM DATE(f.transaction_date)) BETWEEN 2018 AND 2022
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
