select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select payment_key
from "warehouse"."raw_marts"."fct_payments"
where payment_key is null



      
    ) dbt_internal_test