
  
    

  create  table "warehouse"."raw_marts"."dim_employee__dbt_tmp"
  
  
    as
  
  (
    with source as (
    select * from "warehouse"."raw_staging"."stg_employees"
),

stores as (
    select store_key, store_id from "warehouse"."raw_marts"."dim_store"
)

select
    md5(cast(coalesce(cast(e.employee_id as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT))  as employee_key,
    e.employee_id,
    e.full_name,
    e.first_name,
    e.last_name,
    e.email,
    e.role,
    e.hired_date,
    s.store_key,
    e.is_deleted,
    e.created_at,
    e.updated_at
from source e
left join stores s on e.store_id = s.store_id
  );
  