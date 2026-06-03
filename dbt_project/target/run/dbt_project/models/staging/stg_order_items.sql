
  create view "warehouse"."raw_staging"."stg_order_items__dbt_tmp"
    
    
  as (
    with source as (
    select * from "warehouse"."raw"."order_items"
),
renamed as (
    select
        id                                        as order_item_id,
        _extracted_at                             as extracted_at,
        orderid                                   as order_id,
        productid                                 as product_id,
        quantity::integer                         as quantity,
        unitprice::numeric                        as unit_price,
        discountpct::numeric                      as discount_pct,
        linetotal::numeric                        as line_total,
        createdat                                 as created_at,
        updatedat                                 as updated_at
    from source
)
select * from renamed
  );