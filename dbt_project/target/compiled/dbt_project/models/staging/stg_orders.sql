with source as (
    select * from "warehouse"."raw"."orders"
),
renamed as (
    select
        id                                        as order_id,
        _extracted_at                             as extracted_at,
        customerid                                as customer_id,
        storeid                                   as store_id,
        employeeid                                as employee_id,
        status,
        totalamount::numeric                      as total_amount,
        discountamount::numeric                   as discount_amount,
        discountcode                              as discount_code,
        orderedat                                 as ordered_at,
        paidat                                    as paid_at,
        shippedat                                 as shipped_at,
        deliveredat                               as delivered_at,
        cancelledat                               as cancelled_at,
        createdat                                 as created_at,
        updatedat                                 as updated_at
    from source
)
select * from renamed