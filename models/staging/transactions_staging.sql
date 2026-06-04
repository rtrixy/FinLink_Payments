{{ config(materialized='table') }}

with source_data as (
    select * from {{ source('data_finlink', 'transactions') }}
),
final as (
    select * from source_data
)
select * from final