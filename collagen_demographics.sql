select f.transaction_date, p.gender_app_user, p.age_bucket, sum(f.item_quantity) as units_sold
from `standard_nmr_feed_item_table` i
join `standard_nmr_feed_fact_table` f
on i.item_id = f.item_id
and i.batch_date = f.batch_date
join `standard_nmr_feed_people_table` p
on p.user_id = f.user_id
and p.batch_date = f.batch_date
where category_id = 'isc_hea_vit_min_collagen'
AND (
    (f.batch_date='2024-05-13' AND EXTRACT(year FROM DATE(f.transaction_date)) < 2024) OR
    (f.batch_date='2024-10-21' AND EXTRACT(year FROM DATE(f.transaction_date)) >= 2024)
  )
group by 1, 2, 3