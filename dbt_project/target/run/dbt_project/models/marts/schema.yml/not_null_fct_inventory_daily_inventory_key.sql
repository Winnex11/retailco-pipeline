select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select inventory_key
from "warehouse"."raw_marts"."fct_inventory_daily"
where inventory_key is null



      
    ) dbt_internal_test