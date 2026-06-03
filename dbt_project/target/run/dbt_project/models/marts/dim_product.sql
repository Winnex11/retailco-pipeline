
  
    

  create  table "warehouse"."raw_marts"."dim_product__dbt_tmp"
  
  
    as
  
  (
    with snap as (
    select * from "warehouse"."snapshots"."snap_products"
)

select
    md5(cast(coalesce(cast(product_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(dbt_scd_id as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT))  as product_key,
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
  );
  