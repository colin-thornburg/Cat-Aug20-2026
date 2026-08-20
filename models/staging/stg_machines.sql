{{ config(materialized='view') }}

select
    cast(machine_id as number(38, 0)) as machine_id,
    trim(serial_number) as serial_number,
    trim(model) as model,
    trim(family) as machine_family,
    cast(model_year as number(4, 0)) as model_year,
    cast(sold_date as date) as sold_date,
    trim(dealer_region) as dealer_region,
    cast(customer_site_id as number(38, 0)) as site_id
from {{ ref('seed_machines') }}
