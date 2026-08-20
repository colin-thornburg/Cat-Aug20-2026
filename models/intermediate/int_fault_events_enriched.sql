select
    telemetry.reading_id as fault_event_id,
    telemetry.machine_id,
    telemetry.reading_ts as fault_ts,
    telemetry.fault_code,
    faults.fault_description,
    faults.severity,
    faults.subsystem,
    iff(faults.severity = 'CRITICAL', true, false) as is_critical_fault,
    telemetry.engine_hours,
    telemetry.coolant_temp_c,
    telemetry.oil_pressure_psi
from {{ ref('stg_telemetry_readings') }} as telemetry
inner join {{ ref('stg_fault_codes') }} as faults
    on telemetry.fault_code = faults.fault_code
where telemetry.fault_code is not null
