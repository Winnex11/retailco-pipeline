with source as (
    select * from "warehouse"."raw"."customers"
),
renamed as (
    select
        id                                        as customer_id,
        _extracted_at                             as extracted_at,
        firstname                                 as first_name,
        lastname                                  as last_name,
        firstname || ' ' || lastname              as full_name,
        email,
        phone,
        address,
        city,
        state,
        segment,
        tier,
        isdeleted                                 as is_deleted,
        createdat                                 as created_at,
        updatedat                                 as updated_at,
        effectivefrom                             as effective_from,
        registeredat                              as registered_at
    from source
)
select * from renamed