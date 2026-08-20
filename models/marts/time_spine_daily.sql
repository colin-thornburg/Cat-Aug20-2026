{{ config(materialized='table') }}

select
    dateadd('day', seq4(), date '2020-01-01')::date as date_day
from table(generator(rowcount => 3653))
where date_day < date '2030-01-01'
