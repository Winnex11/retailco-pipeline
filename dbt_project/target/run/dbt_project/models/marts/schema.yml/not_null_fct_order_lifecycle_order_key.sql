select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select order_key
from "warehouse"."raw_marts"."fct_order_lifecycle"
where order_key is null



      
    ) dbt_internal_test