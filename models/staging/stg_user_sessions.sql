WITH source AS (
    SELECT * FROM {{ source('dev_raw_bronze', 'raw_user_sessions') }}
),

device_map AS (
    SELECT * FROM {{ ref('map_device_type') }}
),

renamed as (
    SELECT
        s.session_id,
        s.user_id,
        CAST(s.login_date AS DATE) AS login_date,
        COALESCE(dm.clean_device_type, INITCAP(s.device_type)) AS device_type,
        --Limpiamos los 'unknown'
        CASE 
            WHEN s.app_version = 'unknown' THEN NULL 
            ELSE s.app_version 
        END AS app_version,
        -- 4.Corregimos negativos
        CASE 
            WHEN s.session_duration_seconds < 0 THEN 0 
            ELSE s.session_duration_seconds 
        END AS session_duration_seconds

    FROM source s
    LEFT JOIN device_map dm 
        ON LOWER(TRIM(s.device_type)) = dm.raw_device_type
)

select * from renamed