
  
    

  create  table "warehouse"."raw_marts"."dim_payment_method__dbt_tmp"
  
  
    as
  
  (
    with source as (
    select * from "warehouse"."raw_staging"."stg_payment_methods"
)

select
    md5(cast(coalesce(cast(payment_method_id as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT))  as payment_method_key,
    payment_method_id,
    method_name,
    provider,
    is_digital,
    created_at,
    updated_at
from source
  );
  