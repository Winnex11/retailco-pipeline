
      
  
    

  create  table "warehouse"."snapshots"."snap_customers"
  
  
    as
  
  (
    

    select *,
        md5(coalesce(cast(customer_id as varchar ), '')
         || '|' || coalesce(cast(updated_at as varchar ), '')
        ) as dbt_scd_id,
        updated_at as dbt_updated_at,
        updated_at as dbt_valid_from,
        nullif(updated_at, updated_at) as dbt_valid_to
    from (
        



select * from "warehouse"."raw_staging"."stg_customers"

    ) sbq



  );
  
  