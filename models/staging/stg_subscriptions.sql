WITH source AS (
    SELECT * FROM {{ source('dev_raw_bronze', 'raw_subscriptions') }}
    --Numeramos las filas repetidas y nos quedamos solo con la primera (la más reciente.una Clave Primaria (como un ID de sesión, de usuario o de pedido) tiene que ser estrictamente única. Si hay dos iguales, uno de los dos es mentira.
    QUALIFY ROW_NUMBER() OVER(PARTITION BY subscription_id ORDER BY start_date DESC) = 1
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

--Limpieza de textos y cruces
renamed_texts as (
    SELECT
        s.subscription_id,
        s.user_id,
        CAST(s.start_date AS DATE) AS start_date,
        CAST(s.end_date AS DATE) AS end_date,

        --Textos con triple red de seguridad (Seed -> Formato -> 'Unknown')
        COALESCE(pl.clean_plan_name, INITCAP(s.plan_name), 'Unknown') AS plan_name,
        COALESCE(ss.clean_subscription_status, INITCAP(s.status), 'Unknown') AS status,
        COALESCE(pm.clean_payment_method, INITCAP(s.payment_method), 'Unknown') AS payment_method,
        COALESCE(ps.clean_payment_status, INITCAP(s.payment_status), 'Unknown') AS payment_status,
        -- Nos traemos el precio crudo tal cual para calcularlo en el siguiente paso
        s.monthly_price AS raw_monthly_price
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
    ),

-- 3. Segundo paso: Cálculos matemáticos basados en los textos limpios
final as (
    SELECT
        subscription_id,
        user_id,
        plan_name,
        start_date,
        end_date,
        status,
        payment_method,
        payment_status,
        -- Asignación de precio segura y conversión del dato original con fallback a 0.00
        CASE plan_name
            WHEN 'Basic'  THEN 9.99
            WHEN 'Pro'    THEN 19.99
            WHEN 'Elite'  THEN 39.99
            WHEN 'Family' THEN 29.99 
            ELSE COALESCE(ABS(CAST(REPLACE(raw_monthly_price, ',', '.') AS numeric(10,2))), 0.00)
        END AS monthly_price
    from renamed_texts
)


select * from final