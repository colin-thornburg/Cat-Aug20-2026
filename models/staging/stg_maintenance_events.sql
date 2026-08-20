{{ config(materialized='view') }}

select
    cast(event_id as number(38, 0)) as maintenance_event_id,
    cast(machine_id as number(38, 0)) as machine_id,
    cast(event_ts as timestamp_ntz) as event_ts,
    lower(trim(event_type)) as event_type,
    trim(component_replaced) as component_replaced,
    cast(downtime_hours as float) as downtime_hours,
    cast(cost_usd as number(12, 2)) as cost_usd
from {{ ref('seed_maintenance_events') }}
