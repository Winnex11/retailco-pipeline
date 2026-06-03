with source as (
    select * from {{ ref('stg_employees') }}
),

stores as (
    select store_key, store_id from {{ ref('dim_store') }}
)

select
    {{ dbt_utils.generate_surrogate_key(['e.employee_id']) }}  as employee_key,
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