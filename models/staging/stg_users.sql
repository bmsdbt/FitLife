with source as (
    select * from {{ source('dev_raw_bronze', 'raw_users')}}
),
renamed as (
    select 
        user_id,
        initcap(user_name) as user_name,
        lower(email) as email,
        CASE 
            WHEN UPPER(gender) IN ('M', 'MALE') THEN 'Male'
            WHEN UPPER(gender) IN ('F', 'FEMALE') THEN 'Female'
            WHEN gender IS NULL THEN 'Unknown'
            ELSE INITCAP(gender) -- Esto arregla 'non-binary' -> 'Non-Binary' o cualquier otro valor
        END AS gender,
        initcap(city) as city,
        case 
            when age < 0 or age > 100 then null
            else age
        end as age,
    cast(registration_date as date) as registration_at
    from source
    where user_id is not null
        and email is not null
)

select * from renamed