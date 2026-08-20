{{ config(materialized='view') }}

select
    trim(fault_code) as fault_code,
    trim(description) as fault_description,
    upper(trim(severity)) as severity,
    lower(trim(subsystem)) as subsystem
from {{ ref('seed_fault_codes') }}
