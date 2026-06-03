with movements as (
    select * from {{ ref('stg_inventory_movements') }}
),

products as (
    select product_key, product_id
    from {{ ref('dim_product') }}
    where is_current = true
),

stores as (
    select store_key, store_id from {{ ref('dim_store') }}
),

dates as (
    select date_key, full_date from {{ ref('dim_date') }}
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
    {{ dbt_utils.generate_surrogate_key(['dm.product_id', 'dm.store_id', 'dm.movement_date']) }}
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