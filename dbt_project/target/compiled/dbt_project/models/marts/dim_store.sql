with source as (
    select * from "warehouse"."raw_staging"."stg_stores"
)

select
    md5(cast(coalesce(cast(store_id as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT))  as store_key,
    store_id,
    store_name,
    city,
    state,
    address,
    phone,
    manager_name,
    opened_date,
    created_at,
    updated_at
from source