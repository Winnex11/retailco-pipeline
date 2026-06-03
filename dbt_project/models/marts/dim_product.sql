with snap as (
    select * from {{ ref('snap_products') }}
)

select
    {{ dbt_utils.generate_surrogate_key(['product_id', 'dbt_scd_id']) }}  as product_key,
    product_id,
    product_name,
    sku,
    brand,
    category,
    subcategory,
    supplier,
    unit_price,
    cost_price,
    is_deleted,
    dbt_valid_from                             as valid_from,
    dbt_valid_to                               as valid_to,
    case when dbt_valid_to is null
        then true else false end               as is_current
from snap