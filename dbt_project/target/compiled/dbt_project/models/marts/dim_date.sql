with date_spine as (
    select generate_series(
        '2022-01-01'::date,
        '2027-12-31'::date,
        '1 day'::interval
    )::date as full_date
),

nigerian_holidays as (
    select * from (values
        ('2022-01-01'::date, 'New Year Day'),
        ('2022-04-15'::date, 'Good Friday'),
        ('2022-04-18'::date, 'Easter Monday'),
        ('2022-05-01'::date, 'Workers Day'),
        ('2022-06-12'::date, 'Democracy Day'),
        ('2022-10-01'::date, 'Independence Day'),
        ('2022-12-25'::date, 'Christmas Day'),
        ('2022-12-26'::date, 'Boxing Day'),
        ('2023-01-01'::date, 'New Year Day'),
        ('2023-04-07'::date, 'Good Friday'),
        ('2023-04-10'::date, 'Easter Monday'),
        ('2023-05-01'::date, 'Workers Day'),
        ('2023-06-12'::date, 'Democracy Day'),
        ('2023-10-01'::date, 'Independence Day'),
        ('2023-12-25'::date, 'Christmas Day'),
        ('2023-12-26'::date, 'Boxing Day'),
        ('2024-01-01'::date, 'New Year Day'),
        ('2024-03-29'::date, 'Good Friday'),
        ('2024-04-01'::date, 'Easter Monday'),
        ('2024-05-01'::date, 'Workers Day'),
        ('2024-06-12'::date, 'Democracy Day'),
        ('2024-10-01'::date, 'Independence Day'),
        ('2024-12-25'::date, 'Christmas Day'),
        ('2024-12-26'::date, 'Boxing Day'),
        ('2025-01-01'::date, 'New Year Day'),
        ('2025-04-18'::date, 'Good Friday'),
        ('2025-04-21'::date, 'Easter Monday'),
        ('2025-05-01'::date, 'Workers Day'),
        ('2025-06-12'::date, 'Democracy Day'),
        ('2025-10-01'::date, 'Independence Day'),
        ('2025-12-25'::date, 'Christmas Day'),
        ('2025-12-26'::date, 'Boxing Day'),
        ('2026-01-01'::date, 'New Year Day'),
        ('2026-04-03'::date, 'Good Friday'),
        ('2026-04-06'::date, 'Easter Monday'),
        ('2026-05-01'::date, 'Workers Day'),
        ('2026-06-12'::date, 'Democracy Day'),
        ('2026-10-01'::date, 'Independence Day'),
        ('2026-12-25'::date, 'Christmas Day'),
        ('2026-12-26'::date, 'Boxing Day'),
        ('2027-01-01'::date, 'New Year Day'),
        ('2027-03-26'::date, 'Good Friday'),
        ('2027-03-29'::date, 'Easter Monday'),
        ('2027-05-01'::date, 'Workers Day'),
        ('2027-06-12'::date, 'Democracy Day'),
        ('2027-10-01'::date, 'Independence Day'),
        ('2027-12-25'::date, 'Christmas Day'),
        ('2027-12-26'::date, 'Boxing Day')
    ) as t(holiday_date, holiday_name)
)

select
    to_char(d.full_date, 'YYYYMMDD')::int      as date_key,
    d.full_date,
    extract(year from d.full_date)::int         as year,
    extract(quarter from d.full_date)::int      as quarter,
    extract(month from d.full_date)::int        as month,
    to_char(d.full_date, 'Month')               as month_name,
    extract(week from d.full_date)::int         as week,
    extract(isodow from d.full_date)::int       as day_of_week,
    to_char(d.full_date, 'Day')                 as day_name,
    case when extract(isodow from d.full_date) in (6,7)
        then true else false end                as is_weekend,
    case when h.holiday_date is not null
        then true else false end                as is_public_holiday,
    h.holiday_name
from date_spine d
left join nigerian_holidays h on d.full_date = h.holiday_date