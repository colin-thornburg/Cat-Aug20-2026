{{ config(materialized='table') }}

select
    md5(concat_ws('|', machine_id::varchar, model, site_id::varchar, region, date_trunc('day', event_ts)::date::varchar)) as maintenance_cost_id,
    date_trunc('day', event_ts)::date as maintenance_date,
    machine_id,
    model,
    site_id,
    site_name,
    region,
    count(*) as maintenance_event_count,
    count_if(event_type = 'scheduled') as scheduled_event_count,
    count_if(event_type = 'unplanned') as unplanned_event_count,
    sum(downtime_hours) as downtime_hours,
    sum(cost_usd) as maintenance_cost_usd,
    avg(cost_usd) as avg_event_cost_usd
from {{ ref('int_maintenance_with_cost') }}
group by 1, 2, 3, 4, 5, 6, 7

