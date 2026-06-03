
  create view "warehouse"."raw_staging"."stg_products__dbt_tmp"
    
    
  as (
    with source as (
    select * from "warehouse"."raw"."products"
),
renamed as (
    select
        id                                        as product_id,
        _extracted_at                             as extracted_at,
        name                                      as product_name,
        sku,
        brand,
        category,
        subcategory,
        supplier,
        sellingprice::numeric                     as unit_price,
        costprice::numeric                        as cost_price,
        isdeleted                                 as is_deleted,
        createdat                                 as created_at,
        updatedat                                 as updated_at,
        effectivefrom                             as effective_from
    from source
)
select * from renamed
  );