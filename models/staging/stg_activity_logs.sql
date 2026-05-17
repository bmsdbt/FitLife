WITH source AS (
    SELECT * FROM {{ source('dev_raw_bronze', 'raw_activity_logs') }}
),

activity_map AS (
    SELECT * FROM {{ ref('map_activity_type') }}
),

renamed as (
    SELECT
        s.activity_id,
        s.user_id,
        -- Para HIIT solemos usar mayúsculas, para el resto Initcap.
        CASE 
            WHEN LOWER(TRIM(s.activity_type)) IN ('hiit', 'h.i.i.t') THEN 'HIIT'
            ELSE COALESCE(am.clean_activity_type, INITCAP(s.activity_type))
        END AS activity_type,
        -- Limpieza de valores imposibles. Si es negativo o mayor a 12 horas (720 min), lo ponemos a NULL o 0 para no sesgar
        CASE 
            WHEN s.duration_minutes < 0 OR s.duration_minutes > 720 THEN NULL 
            ELSE s.duration_minutes 
        END AS duration_minutes,
        --Limpieza de negativos para las calorias también
        CASE 
            WHEN s.calories_burned < 0 THEN 0 
            ELSE s.calories_burned 
        END AS calories_burned,
        CAST(s.activity_date AS DATE) AS activity_date

    FROM source s
    LEFT JOIN activity_map am
        ON LOWER(TRIM(s.activity_type)) = am.raw_activity_type
)

select * from renamed