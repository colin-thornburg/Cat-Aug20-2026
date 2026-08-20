{{ config(materialized='view') }}

select
    cast(reading_id as number(38, 0)) as reading_id,
    cast(machine_id as number(38, 0)) as machine_id,
    cast(reading_ts as timestamp_ntz) as reading_ts,
    cast(engine_hours as float) as engine_hours,
    cast(fuel_rate_gph as float) as fuel_rate_gph,
    cast(coolant_temp_c as float) as coolant_temp_c,
    cast(oil_pressure_psi as float) as oil_pressure_psi,
    cast(payload_tons as float) as payload_tons,
    cast(idle_flag as boolean) as is_idle,
    nullif(trim(fault_code), '') as fault_code
from {{ ref('seed_telemetry_readings') }}
