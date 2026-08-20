{{ config(materialized='table') }}

-- Feast FeatureView mapping:
--   entity: machine_id
--   event timestamp: feature_timestamp (TIMESTAMP_NTZ at the end of feature_date)
--   features: all columns following feature_timestamp
-- Each feature uses events on or before feature_date only, making the row safe for point-in-time training joins.

with machine_bounds as (
    select
        machine_id,
        min(telemetry_date) as first_telemetry_date,
        max(telemetry_date) as last_telemetry_date
    from {{ ref('int_machine_daily_telemetry') }}
    group by 1
),

machine_calendar as (
    select
        bounds.machine_id,
        spine.date_day as feature_date
    from machine_bounds as bounds
    inner join {{ ref('time_spine_daily') }} as spine
        on spine.date_day between bounds.first_telemetry_date and bounds.last_telemetry_date
),

daily_telemetry as (
    select
        machine_id,
        telemetry_date,
        avg_fuel_rate_gph,
        engine_hours_delta,
        avg_payload_tons
    from {{ ref('int_machine_daily_telemetry') }}
),

daily_faults as (
    select
        machine_id,
        fault_ts::date as fault_date,
        count_if(is_critical_fault) as critical_fault_count
    from {{ ref('int_fault_events_enriched') }}
    group by 1, 2
),

daily_maintenance as (
    select
        machine_id,
        event_ts::date as maintenance_date,
        count(*) as maintenance_event_count
    from {{ ref('int_maintenance_with_cost') }}
    group by 1, 2
),

feature_inputs as (
    select
        calendar.machine_id,
        calendar.feature_date,
        telemetry.avg_fuel_rate_gph,
        telemetry.engine_hours_delta,
        telemetry.avg_payload_tons,
        coalesce(faults.critical_fault_count, 0) as critical_fault_count,
        coalesce(maintenance.maintenance_event_count, 0) as maintenance_event_count
    from machine_calendar as calendar
    left join daily_telemetry as telemetry
        on calendar.machine_id = telemetry.machine_id
        and calendar.feature_date = telemetry.telemetry_date
    left join daily_faults as faults
        on calendar.machine_id = faults.machine_id
        and calendar.feature_date = faults.fault_date
    left join daily_maintenance as maintenance
        on calendar.machine_id = maintenance.machine_id
        and calendar.feature_date = maintenance.maintenance_date
),

windowed_features as (
    select
        *,
        max(iff(maintenance_event_count > 0, feature_date, null)) over (
            partition by machine_id
            order by feature_date
            rows between unbounded preceding and current row
        ) as last_maintenance_date
    from feature_inputs
)

select
    -- dbt surrogate key; Feast uses machine_id + feature_timestamp as the logical row identity.
    md5(concat_ws('|', machine_id::varchar, feature_date::varchar)) as machine_failure_prediction_feature_id,
    -- Feast entity join key.
    machine_id,
    -- Feast event timestamp. Feature values represent information available at the end of this calendar day.
    feature_date::timestamp_ntz as feature_timestamp,
    -- Feast feature: mean of daily fuel-rate observations in the trailing seven calendar days.
    avg(avg_fuel_rate_gph) over (
        partition by machine_id
        order by feature_date
        rows between 6 preceding and current row
    ) as rolling_7d_avg_fuel_rate_gph,
    -- Feast feature: total observed engine-hour delta in the trailing seven calendar days.
    sum(coalesce(engine_hours_delta, 0)) over (
        partition by machine_id
        order by feature_date
        rows between 6 preceding and current row
    ) as rolling_7d_engine_hour_delta,
    -- Feast feature: CRITICAL diagnostic events in the trailing 30 calendar days.
    sum(critical_fault_count) over (
        partition by machine_id
        order by feature_date
        rows between 29 preceding and current row
    ) as critical_fault_count_30d,
    -- Feast feature: calendar days since the last recorded maintenance event; null means no prior event exists.
    datediff('day', last_maintenance_date, feature_date) as days_since_last_maintenance,
    -- Feast feature: sample variance of daily average payload in the trailing seven calendar days.
    var_samp(avg_payload_tons) over (
        partition by machine_id
        order by feature_date
        rows between 6 preceding and current row
    ) as payload_variance_7d
from windowed_features
