-- CTE "poly": Selects county borders and names for two specific counties
WITH poly AS (
  SELECT 
    c.geometry AS county_borders, -- The geographic boundary of the county
    c.name AS county_name,        -- The county name
    s.name AS state_name          -- The state name
  FROM `demo.us_political_boundaries.us_counties` c
  -- Join to the states table to get state names corresponding to the county
  JOIN `demo.us_political_boundaries.us_states` s
    ON s.state = c.state
  WHERE (
    -- Filter to include only St. Clair County in Illinois or St. Louis County in Missouri
    (s.name = 'Illinois' AND c.name = 'St. Clair') OR
    (s.name = 'Missouri' AND c.name = 'St. Louis')
  )
  AND c.lsad = 'County'  -- Ensure the record represents a county
),
-- CTE "bbox": Computes a bounding box that covers the selected counties
bbox AS (
  SELECT 
    MIN(ST_BOUNDINGBOX(county_borders)[OFFSET(0)]) AS long_min, -- Smallest longitude among the county boxes
    MIN(ST_BOUNDINGBOX(county_borders)[OFFSET(1)]) AS lat_min,  -- Smallest latitude among the county boxes
    MAX(ST_BOUNDINGBOX(county_borders)[OFFSET(2)]) AS long_max, -- Largest longitude among the county boxes
    MAX(ST_BOUNDINGBOX(county_borders)[OFFSET(3)]) AS lat_max  -- Largest latitude among the county boxes
  FROM poly
),
-- CTE "item_batch": Retrieves the latest batch date for each item to ensure up-to-date item records
item_batch AS (
  SELECT 
    item_id, 
    MAX(DATE(batch_date)) AS latest_batch_date -- Latest date for each item
  FROM `kellogg.numerator.standard_nmr_feed_item_table`
  GROUP BY item_id
),
-- CTE "trans_batch": Retrieves the latest batch date for each transaction date to ensure up-to-date transaction records
trans_batch AS (
  SELECT 
    transaction_date, 
    MAX(DATE(batch_date)) AS latest_batch_date -- Latest date for each transaction date
  FROM `kellogg.numerator.standard_nmr_feed_fact_table`
  GROUP BY transaction_date
),
-- CTE "sales_bbox": Filters transactions based on geographic and other business criteria
sales_bbox AS (
  SELECT 
    t.transaction_date, 
    ST_GEOGPOINT(t.longitude, t.latitude) AS trans_geopoint, -- Converts longitude/latitude to a geography point
    t.item_total
  FROM `kellogg.numerator.standard_nmr_feed_item_table` i
  -- Join fact table on item_id to link item records with their transactions
  JOIN `kellogg.numerator.standard_nmr_feed_fact_table` t
    ON i.item_id = t.item_id
  -- Ensure using the most recent item record from the batch
  JOIN item_batch ib
    ON i.item_id = ib.item_id
    AND DATE(i.batch_date) = ib.latest_batch_date
  -- Ensure using the most recent transaction record from the batch
  JOIN trans_batch tb
    ON t.transaction_date = tb.transaction_date
    AND DATE(t.batch_date) = tb.latest_batch_date
  -- Join the bounding box to filter transactions that fall within the geographic extent of the selected counties
  JOIN bbox
    ON t.latitude BETWEEN bbox.lat_min AND bbox.lat_max
    AND t.longitude BETWEEN bbox.long_min AND bbox.long_max
  WHERE 
    -- Filter for transactions belonging to the specific department
    i.dept_id = 'isc_gro_bev_beer_wine_and_spirits'
    -- Include transactions between 2018 and 2022 (inclusive)
    AND EXTRACT(YEAR FROM DATE(t.transaction_date)) BETWEEN 2018 AND 2022
)
-- Final query: Aggregates sales by year, month, and county
SELECT 
  EXTRACT(YEAR FROM DATE(s.transaction_date)) AS trans_year,  -- Extracts the transaction year
  EXTRACT(MONTH FROM DATE(s.transaction_Date)) AS trans_month,   -- Extracts the transaction month
  p.county_name,                                               -- County name from the "poly" CTE
  p.state_name,                                                -- State name from the "poly" CTE
  SUM(s.item_total) AS total_sales                             -- Total sales aggregated by the groupings
FROM sales_bbox s
-- Join with the "poly" CTE to link transactions to county boundaries using spatial matching
JOIN poly p
  ON ST_COVERS(
       ST_BUFFER(p.county_borders, 2000), -- Create a 2000-meter buffer around the county borders for looser spatial matching
       ST_BUFFER(s.trans_geopoint, 2000)    -- Create a 2000-meter buffer around the transaction location
     )
WHERE 
  -- Further ensure that the county borders contain the exact transaction point
  ST_CONTAINS(p.county_borders, s.trans_geopoint)
GROUP BY 1, 2, 3, 4;
