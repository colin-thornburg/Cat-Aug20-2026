{{ config(materialized='view') }}

select
    cast(order_id as number(38, 0)) as parts_order_id,
    cast(machine_id as number(38, 0)) as machine_id,
    cast(order_ts as timestamp_ntz) as order_ts,
    trim(part_number) as part_number,
    cast(quantity as number(38, 0)) as quantity,
    lower(trim(order_status)) as order_status,
    cast(lead_time_days as number(38, 0)) as lead_time_days
from {{ ref('seed_parts_orders') }}
