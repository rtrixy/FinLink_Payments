

with source_data as (
    select * from {{ source('data_finlink', 'ip_geolocation') }}
),
final as (
    select * from source_data
)
select * from final