
  create view "warehouse"."raw_staging"."stg_payment_methods__dbt_tmp"
    
    
  as (
    with source as (
    select * from "warehouse"."raw"."payment_methods"
),
renamed as (
    select
        id                                        as payment_method_id,
        _extracted_at                             as extracted_at,
        name                                      as method_name,
        provider,
        isdigital                                 as is_digital,
        createdat                                 as created_at,
        updatedat                                 as updated_at
    from source
)
select * from renamed
  );