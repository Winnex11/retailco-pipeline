
  
    

  create  table "warehouse"."raw_marts"."fct_inventory_daily__dbt_tmp"
  
  
    as
  
  (
    with movements as (
    select * from "warehouse"."raw_staging"."stg_inventory_movements"
),

products as (
    select product_key, product_id
    from "warehouse"."raw_marts"."dim_product"
    where is_current = true
),

stores as (
    select store_key, store_id from "warehouse"."raw_marts"."dim_store"
),

dates as (
    select date_key, full_date from "warehouse"."raw_marts"."dim_date"
),

daily_movements as (
    select
        product_id,
        store_id,
        moved_at::date                          as movement_date,
        sum(case when movement_type = 'in'
            then quantity else 0 end)           as units_received,
        sum(case when movement_type = 'out'
            then quantity else 0 end)           as units_sold,
        sum(case when movement_type = 'in'
            then quantity
            when movement_type = 'out'
            then -quantity else 0 end)          as net_movement
    from movements
    group by product_id, store_id, moved_at::date
)

select
    md5(cast(coalesce(cast(dm.product_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(dm.store_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(dm.movement_date as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT))
                                                as inventory_key,
    d.date_key,
    p.product_key,
    s.store_key,
    dm.units_received,
    dm.units_sold,
    dm.net_movement,
    dm.movement_date
from daily_movements dm
left join products p  on dm.product_id = p.product_id
left join stores s    on dm.store_id = s.store_id
left join dates d     on dm.movement_date = d.full_date
  );
  