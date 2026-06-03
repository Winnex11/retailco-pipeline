with payments as (
    select * from "warehouse"."raw_staging"."stg_payments"
    where amount_paid is not null
    and not (
        amount_paid = 0
        or (amount_paid < 0 and status != 'refund')
    )
),

customers as (
    select customer_key, customer_id
    from "warehouse"."raw_marts"."dim_customer"
    where is_current = true
),

payment_methods as (
    select payment_method_key, payment_method_id
    from "warehouse"."raw_marts"."dim_payment_method"
),

dates as (
    select date_key, full_date from "warehouse"."raw_marts"."dim_date"
)

select
    md5(cast(coalesce(cast(p.payment_id as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT))       as payment_key,
    p.payment_id,
    d.date_key,
    c.customer_key,
    pm.payment_method_key,
    p.order_id,
    p.amount_paid,
    p.currency,
    p.status,
    p.payment_type,
    case when p.amount_paid < 0 then true else false end            as is_refund,
    p.paid_at,
    p.created_at,
    p.updated_at
from payments p
left join customers c         on p.customer_id = c.customer_id
left join payment_methods pm  on p.payment_method_id = pm.payment_method_id
left join dates d             on p.paid_at::date = d.full_date