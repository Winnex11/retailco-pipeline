
  create view "warehouse"."raw_staging"."stg_stores__dbt_tmp"
    
    
  as (
    with source as (
    select * from "warehouse"."raw"."stores"
),
renamed as (
    select
        id                                        as store_id,
        _extracted_at                             as extracted_at,
        name                                      as store_name,
        city,
        state,
        address,
        phone,
        managername                               as manager_name,
        openeddate                                as opened_date,
        createdat                                 as created_at,
        updatedat                                 as updated_at
    from source
)
select * from renamed
  );