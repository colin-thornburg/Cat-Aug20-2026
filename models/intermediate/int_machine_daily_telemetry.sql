with deduplicated_readings as (
    select *
    from {{ ref('stg_telemetry_readings') }}
    qualify row_number() over (
        partition by machine_id, reading_ts
        order by reading_id desc
    ) = 1
),

daily_rollup as (
    select
        machine_id,
        date_trunc('day', reading_ts)::date as telemetry_date,
        min(engine_hours) as starting_engine_hours,
        max(engine_hours) as ending_engine_hours,
        avg(fuel_rate_gph) as avg_fuel_rate_gph,
        avg(payload_tons) as avg_payload_tons,
        max(coolant_temp_c) as max_coolant_temp_c,
        avg(iff(is_idle, 1.0, 0.0)) as idle_ratio,
        count(*) as reading_count
    from deduplicated_readings
    group by 1, 2
)

select
    md5(concat_ws('|', machine_id::varchar, telemetry_date::varchar)) as machine_daily_telemetry_id,
    machine_id,
    telemetry_date,
    starting_engine_hours,
    ending_engine_hours,
    ending_engine_hours - starting_engine_hours as engine_hours_delta,
    avg_fuel_rate_gph,
    avg_payload_tons,
    max_coolant_temp_c,
    idle_ratio,
    reading_count
from daily_rollup
