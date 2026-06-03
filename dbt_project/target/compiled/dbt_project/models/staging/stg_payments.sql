with source as (
    select * from "warehouse"."raw"."payments"
),
renamed as (
    select
        id                                        as payment_id,
        _extracted_at                             as extracted_at,
        orderid                                   as order_id,
        customerid                                as customer_id,
        paymentmethodid                           as payment_method_id,
        amountpaid::numeric                       as amount_paid,
        currency,
        status,
        paymenttype                               as payment_type,
        reference,
        paidat                                    as paid_at,
        createdat                                 as created_at,
        updatedat                                 as updated_at
    from source
)
select * from renamed