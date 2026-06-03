
  
    

  create  table "warehouse"."raw_marts"."fct_sales__dbt_tmp"
  
  
    as
  
  (
    with order_items as (
    select * from "warehouse"."raw_staging"."stg_order_items"
),

orders as (
    select * from "warehouse"."raw_staging"."stg_orders"
),

customers as (
    select customer_key, customer_id
    from "warehouse"."raw_marts"."dim_customer"
    where is_current = true
),

products as (
    select product_key, product_id
    from "warehouse"."raw_marts"."dim_product"
    where is_current = true
),

stores as (
    select store_key, store_id from "warehouse"."raw_marts"."dim_store"
),

employees as (
    select employee_key, employee_id from "warehouse"."raw_marts"."dim_employee"
),

dates as (
    select date_key, full_date from "warehouse"."raw_marts"."dim_date"
)

select
    md5(cast(coalesce(cast(oi.order_item_id as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT))   as sales_key,
    oi.order_item_id,
    coalesce(d.date_key,
        to_char(coalesce(oi.created_at, o.ordered_at,
            '2022-01-01'::timestamp), 'YYYYMMDD')::int)            as date_key,
    c.customer_key,
    p.product_key,
    s.store_key,
    e.employee_key,
    oi.quantity,
    oi.unit_price,
    oi.discount_pct,
    oi.line_total                                                   as gross_amount,
    oi.line_total - (
        oi.line_total * coalesce(oi.discount_pct, 0) / 100
    )                                                               as net_amount,
    oi.created_at,
    oi.updated_at
from order_items oi
left join orders o        on oi.order_id = o.order_id
left join customers c     on o.customer_id = c.customer_id
left join products p      on oi.product_id = p.product_id
left join stores s        on o.store_id = s.store_id
left join employees e     on o.employee_id = e.employee_id
left join dates d         on coalesce(
                                oi.created_at,
                                o.ordered_at
                            )::date = d.full_date
  );
  