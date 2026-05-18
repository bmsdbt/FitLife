WITH source AS (
    SELECT * FROM {{ source('dev_raw_bronze', 'raw_user_sessions') }}
    --Numeramos las filas repetidas y nos quedamos solo con la primera (la más reciente.una Clave Primaria (como un ID de sesión, de usuario o de pedido) tiene que ser estrictamente única. Si hay dos iguales, uno de los dos es mentira.
    QUALIFY ROW_NUMBER() OVER(PARTITION BY session_id ORDER BY login_date DESC) = 1
),

device_map AS (
    SELECT * FROM {{ ref('map_device_type') }}
),

renamed as (
    SELECT
        s.session_id,
        s.user_id,
        CAST(s.login_date AS DATE) AS login_date,
        COALESCE(dm.clean_device_type, INITCAP(s.device_type), 'Unknown') AS device_type,
        --Limpiamos los 'unknown'
        CASE 
            WHEN s.app_version IS NULL OR LOWER(TRIM(s.app_version)) = 'unknown' THEN 'Unknown'
            ELSE s.app_version 
        END AS app_version,
        -- 4.Corregimos negativos
        CASE 
            WHEN s.session_duration_seconds IS NULL OR s.session_duration_seconds < 0 THEN 0 
            ELSE s.session_duration_seconds 
        END AS session_duration_seconds

    FROM source s
    LEFT JOIN device_map dm 
        ON LOWER(TRIM(s.device_type)) = dm.raw_device_type
)

select * from renamed