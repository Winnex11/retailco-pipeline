
  
    

  create  table "warehouse"."raw_marts"."flagged_payments__dbt_tmp"
  
  
    as
  
  (
    with payments as (
    select * from "warehouse"."raw_staging"."stg_payments"
)

select
    md5(cast(coalesce(cast(payment_id as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT))         as flag_key,
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
  );
  