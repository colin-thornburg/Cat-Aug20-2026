select
    maintenance.maintenance_event_id,
    maintenance.machine_id,
    maintenance.event_ts,
    maintenance.event_type,
    maintenance.component_replaced,
    maintenance.downtime_hours,
    maintenance.cost_usd,
    machines.model,
    machines.machine_family,
    machines.site_id,
    sites.site_name,
    sites.industry,
    sites.country,
    sites.region
from {{ ref('stg_maintenance_events') }} as maintenance
inner join {{ ref('stg_machines') }} as machines
    on maintenance.machine_id = machines.machine_id
inner join {{ ref('stg_customer_sites') }} as sites
    on machines.site_id = sites.site_id
