{{ config(
    materialized= 'table'
)}}

with source_users as (
    select * from {{ ref('stg_users')}}
),

final_users as (
    select  
        {{ dbt_utils.generate_surrogate_key(['user_id']) }} as sk_user,
        user_id,
        user_name,
        email,
        gender,
        city,
        age,
        registration_at
from source_users
)

select * from final_users

