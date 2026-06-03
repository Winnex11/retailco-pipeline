
    
    

select
    customer_key as unique_field,
    count(*) as n_records

from "warehouse"."raw_marts"."dim_customer"
where customer_key is not null
group by customer_key
having count(*) > 1


