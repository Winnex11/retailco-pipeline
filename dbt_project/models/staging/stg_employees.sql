with source as (
    select * from {{ source('raw', 'employees') }}
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