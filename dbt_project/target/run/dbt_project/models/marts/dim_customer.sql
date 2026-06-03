
  
    

  create  table "warehouse"."raw_marts"."dim_customer__dbt_tmp"
  
  
    as
  
  (
    with snap as (
    select * from "warehouse"."snapshots"."snap_customers"
)

select
    md5(cast(coalesce(cast(customer_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(dbt_scd_id as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT))  as customer_key,
    customer_id,
    full_name,
    first_name,
    last_name,
    email,
    phone,
    address,
    city,
    state,
    segment,
    tier,
    is_deleted,
    dbt_valid_from                             as valid_from,
    dbt_valid_to                               as valid_to,
    case when dbt_valid_to is null
        then true else false end               as is_current
from snap
  );
  