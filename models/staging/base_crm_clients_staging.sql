{{ config(materialized='table') }}

with source_data as (
    select * from {{ source('data_finlink', 'base_crm_clients') }}
),
final as (
    select * from source_data
)
select * from final