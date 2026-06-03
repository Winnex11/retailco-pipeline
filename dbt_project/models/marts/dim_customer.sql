with snap as (
    select * from {{ ref('snap_customers') }}
)

select
    {{ dbt_utils.generate_surrogate_key(['customer_id', 'dbt_scd_id']) }}  as customer_key,
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