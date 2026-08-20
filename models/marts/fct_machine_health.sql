{{ config(materialized='table') }}

with telemetry_metrics as (
    select
        machine_id,
        max(telemetry_date) as latest_telemetry_date,
        min(telemetry_date) as first_telemetry_date,
        min(starting_engine_hours) as first_engine_hours,
        max(ending_engine_hours) as latest_engine_hours,
        sum(reading_count) as telemetry_reading_count,
        sum(avg_fuel_rate_gph * reading_count) / nullif(sum(reading_count), 0) as avg_fuel_rate_gph,
        max(max_coolant_temp_c) as max_coolant_temp_c,
        sum(idle_ratio * reading_count) / nullif(sum(reading_count), 0) as idle_ratio
    from {{ ref('int_machine_daily_telemetry') }}
    group by 1
),

fault_metrics as (
    select
        machine_id,
        count(*) as fault_event_count,
        count_if(severity = 'INFO') as info_fault_count,
        count_if(severity = 'WARN') as warn_fault_count,
        count_if(severity = 'CRITICAL') as critical_fault_count
    from {{ ref('int_fault_events_enriched') }}
    group by 1
),

maintenance_metrics as (
    select
        machine_id,
        sum(downtime_hours) as downtime_hours,
        sum(cost_usd) as maintenance_cost_usd
    from {{ ref('int_maintenance_with_cost') }}
    group by 1
)

select
    cast(machines.machine_id as number(38, 0)) as machine_health_id,
    cast(machines.machine_id as number(38, 0)) as machine_id,
    cast(telemetry.latest_telemetry_date as date) as latest_telemetry_date,
    cast(coalesce(telemetry.telemetry_reading_count, 0) as number(38, 0)) as telemetry_reading_count,
    cast(greatest(coalesce(telemetry.latest_engine_hours - telemetry.first_engine_hours, 0), 0) as float) as total_engine_hours,
    cast(greatest(coalesce(telemetry.latest_engine_hours - telemetry.first_engine_hours, 0), 0) as float) as active_hours,
    cast(
        coalesce(
            datediff(
                'hour',
                telemetry.first_telemetry_date,
                dateadd('day', 1, telemetry.latest_telemetry_date)
            ),
            0
        )
        as float
    ) as available_hours,

    cast(coalesce(telemetry.avg_fuel_rate_gph, 0) as float) as avg_fuel_rate_gph,
    cast(coalesce(telemetry.max_coolant_temp_c, 0) as float) as max_coolant_temp_c,
    cast(coalesce(telemetry.idle_ratio, 0) as float) as idle_ratio,
    cast(coalesce(faults.fault_event_count, 0) as number(38, 0)) as fault_event_count,
    cast(coalesce(faults.info_fault_count, 0) as number(38, 0)) as info_fault_count,
    cast(coalesce(faults.warn_fault_count, 0) as number(38, 0)) as warn_fault_count,
    cast(coalesce(faults.critical_fault_count, 0) as number(38, 0)) as critical_fault_count,
    cast(coalesce(maintenance.downtime_hours, 0) as float) as downtime_hours,
    cast(coalesce(maintenance.maintenance_cost_usd, 0) as number(14, 2)) as maintenance_cost_usd,
    cast(
        greatest(
            0.0,
            100.0 - (
                coalesce(maintenance.downtime_hours, 0)
                / nullif(coalesce(telemetry.telemetry_reading_count, 0) * 24.0, 0)
                * 100.0
            )
        )
        as float
    ) as uptime_pct
from {{ ref('dim_machine') }} as machines
left join telemetry_metrics as telemetry
    on machines.machine_id = telemetry.machine_id
left join fault_metrics as faults
    on machines.machine_id = faults.machine_id
left join maintenance_metrics as maintenance
    on machines.machine_id = maintenance.machine_id
