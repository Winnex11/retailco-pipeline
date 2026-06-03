
    
    

select
    payment_method_id as unique_field,
    count(*) as n_records

from "warehouse"."raw_staging"."stg_payment_methods"
where payment_method_id is not null
group by payment_method_id
having count(*) > 1


