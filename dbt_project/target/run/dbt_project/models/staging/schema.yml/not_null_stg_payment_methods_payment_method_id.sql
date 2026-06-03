select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select payment_method_id
from "warehouse"."raw_staging"."stg_payment_methods"
where payment_method_id is null



      
    ) dbt_internal_test