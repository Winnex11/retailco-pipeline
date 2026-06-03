
    
    

select
    order_key as unique_field,
    count(*) as n_records

from "warehouse"."raw_marts"."fct_order_lifecycle"
where order_key is not null
group by order_key
having count(*) > 1


