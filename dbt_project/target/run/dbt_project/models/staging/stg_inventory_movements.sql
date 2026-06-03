
  create view "warehouse"."raw_staging"."stg_inventory_movements__dbt_tmp"
    
    
  as (
    with source as (
    select * from "warehouse"."raw"."inventory_movements"
),
renamed as (
    select
        id                                        as movement_id,
        _extracted_at                             as extracted_at,
        productid                                 as product_id,
        storeid                                   as store_id,
        movementtype                              as movement_type,
        quantity::integer                         as quantity,
        referenceid                               as reference_id,
        referencetype                             as reference_type,
        notes,
        movedat                                   as moved_at,
        createdat                                 as created_at,
        updatedat                                 as updated_at
    from source
)
select * from renamed
  );