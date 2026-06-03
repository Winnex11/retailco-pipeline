with payments as (
    select * from {{ ref('stg_payments') }}
)

select
    {{ dbt_utils.generate_surrogate_key(['payment_id']) }}         as flag_key,
    payment_id,
    order_id,
    customer_id,
    amount_paid,
    status,
    case
        when amount_paid = 0 then 'zero_amount'
        when amount_paid < 0 and status != 'refund' then 'unexplained_negative'
        else 'unknown'
    end                                                             as flag_reason,
    created_at                                                      as flagged_at
from payments
where amount_paid = 0
   or (amount_paid < 0 and status != 'refund')