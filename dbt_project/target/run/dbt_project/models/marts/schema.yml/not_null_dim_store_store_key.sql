select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select store_key
from "warehouse"."raw_marts"."dim_store"
where store_key is null



      
    ) dbt_internal_test