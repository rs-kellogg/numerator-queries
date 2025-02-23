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