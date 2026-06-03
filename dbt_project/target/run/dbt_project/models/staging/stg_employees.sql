
  create view "warehouse"."raw_staging"."stg_employees__dbt_tmp"
    
    
  as (
    with source as (
    select * from "warehouse"."raw"."employees"
),
renamed as (
    select
        id                                        as employee_id,
        _extracted_at                             as extracted_at,
        firstname                                 as first_name,
        lastname                                  as last_name,
        firstname || ' ' || lastname              as full_name,
        email,
        role,
        storeid                                   as store_id,
        isdeleted                                 as is_deleted,
        hireddate                                 as hired_date,
        createdat                                 as created_at,
        updatedat                                 as updated_at
    from source
)
select * from renamed
  );