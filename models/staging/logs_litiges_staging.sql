{{ config(materialized='table') }}

with source_data as (
    select * from {{ source('data_finlink', 'logs_litiges') }}
),
final as (
    select * from source_data
)
select * from final