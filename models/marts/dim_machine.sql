{{ config(materialized='table') }}

select
    cast(machines.machine_id as number(38, 0)) as machine_id,
    cast(machines.serial_number as varchar) as serial_number,
    cast(machines.model as varchar) as model,
    cast(machines.machine_family as varchar) as machine_family,
    cast(machines.model_year as number(4, 0)) as model_year,
    cast(machines.sold_date as date) as sold_date,
    cast(machines.dealer_region as varchar) as dealer_region,
    cast(sites.site_id as number(38, 0)) as site_id,
    cast(sites.site_name as varchar) as site_name,
    cast(sites.industry as varchar) as industry,
    cast(sites.country as varchar) as country,
    cast(sites.region as varchar) as region,
    cast(sites.latitude as float) as latitude,
    cast(sites.longitude as float) as longitude
from {{ ref('stg_machines') }} as machines
inner join {{ ref('stg_customer_sites') }} as sites
    on machines.site_id = sites.site_id
