
    
    

select
    inventory_key as unique_field,
    count(*) as n_records

from "warehouse"."raw_marts"."fct_inventory_daily"
where inventory_key is not null
group by inventory_key
having count(*) > 1


