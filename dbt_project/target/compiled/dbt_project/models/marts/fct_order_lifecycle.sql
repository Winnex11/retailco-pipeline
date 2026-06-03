with orders as (
    select * from "warehouse"."raw_staging"."stg_orders"
),

customers as (
    select customer_key, customer_id
    from "warehouse"."raw_marts"."dim_customer"
    where is_current = true
),

stores as (
    select store_key, store_id from "warehouse"."raw_marts"."dim_store"
),

employees as (
    select employee_key, employee_id from "warehouse"."raw_marts"."dim_employee"
),

payment_methods as (
    select payment_method_key, payment_method_id
    from "warehouse"."raw_marts"."dim_payment_method"
),

payments as (
    select distinct on (order_id)
        order_id,
        payment_method_id
    from "warehouse"."raw_staging"."stg_payments"
    order by order_id, created_at desc
),

dates as (
    select date_key, full_date from "warehouse"."raw_marts"."dim_date"
)

select
    md5(cast(coalesce(cast(o.order_id as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT))         as order_key,
    o.order_id,
    d.date_key,
    c.customer_key,
    s.store_key,
    e.employee_key,
    pm.payment_method_key,
    o.ordered_at                                                    as pending_at,
    o.paid_at,
    o.shipped_at,
    o.delivered_at,
    o.cancelled_at,
    o.total_amount                                                  as order_total,
    o.discount_amount,
    o.status,
    o.created_at,
    o.updated_at
from orders o
left join customers c      on o.customer_id = c.customer_id
left join stores s         on o.store_id = s.store_id
left join employees e      on o.employee_id = e.employee_id
left join payments pay     on o.order_id = pay.order_id
left join payment_methods pm on pay.payment_method_id = pm.payment_method_id
left join dates d          on o.ordered_at::date = d.full_date