WITH source AS (
    SELECT * FROM {{ source('dev_raw_bronze', 'raw_subscriptions') }}
),

-- Cargamos todas las seeds necesarias
plan_name_map AS (
    SELECT * FROM {{ ref('map_plan_name') }}
),
subscription_status_map AS (
    SELECT * FROM {{ ref('map_subscription_status') }}
),
payment_method_map AS (
    SELECT * FROM {{ ref('map_payment_methods')}}
),
payment_status_map AS (
    SELECT * FROM {{ ref('map_payment_status') }}
),

renamed as (
    SELECT
        s.subscription_id,
        s.user_id,
        COALESCE(pl.clean_plan_name, INITCAP(s.plan_name)) AS plan_name,
        CAST(s.start_date AS DATE) AS start_date,
        CAST(s.end_date AS DATE) AS end_date,
        COALESCE(ss.clean_subscription_status, INITCAP(s.status)) AS status,
        CAST(REPLACE(s.monthly_price, ',', '.') AS numeric(5,2)) AS monthly_price,
        COALESCE(pm.clean_payment_method, INITCAP(s.payment_method)) AS payment_method,
        COALESCE(ps.clean_payment_status, s.payment_status) AS payment_status

    FROM source s
    -- Joins para todas las limpiezas
    LEFT JOIN plan_name_map pl 
        ON LOWER(TRIM(s.plan_name)) = pl.raw_plan_name
    LEFT JOIN subscription_status_map ss 
        ON LOWER(TRIM(s.status)) = ss.raw_subscription_status
    LEFT JOIN payment_method_map pm 
        ON LOWER(TRIM(s.payment_method)) = pm.raw_payment_method
    LEFT JOIN payment_status_map ps 
        ON LOWER(TRIM(s.payment_status)) = ps.raw_payment_status
    )

select * from renamed