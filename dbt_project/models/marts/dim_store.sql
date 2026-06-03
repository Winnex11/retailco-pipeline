with source as (
    select * from {{ ref('stg_stores') }}
)

select
    {{ dbt_utils.generate_surrogate_key(['store_id']) }}  as store_key,
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