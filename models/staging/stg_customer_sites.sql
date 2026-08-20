{{ config(materialized='view') }}

select
    cast(site_id as number(38, 0)) as site_id,
    trim(site_name) as site_name,
    upper(trim(industry)) as industry,
    trim(country) as country,
    trim(region) as region,
    cast(latitude as float) as latitude,
    cast(longitude as float) as longitude
from {{ ref('seed_customer_sites') }}
