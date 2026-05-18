{{ config(
    materialized= 'table'
)}}

--CTEs de fuentes para cargar las tablas que necesito
with dim_users as (
    select * from {{ ref('dim_users')}}
),

dim_date as (
    select * from {{ ref('dim_date')}}
),

dim_plan_subscription as (
    select * from {{ ref('dim_plan_subscription')}}
),

user_sessions as (
    select * from {{ ref('stg_user_sessions')}} --#CTE del staging para eventos transaccionales
),

--CTE de transfromación para calcular métricas y filtrar. Los cálculos van antes de los joins
session_data as (
    select
        us.session_id,
        us.user_id,
        us.login_date,
        us.device_type,
        us.app_version,
        us.session_duration_seconds,
        ps.sk_subscription,
        ps.status,
         -- is_churned = estado suscripción
        CASE
            WHEN ps.status IN ('Cancelled', 'Expired')
                THEN TRUE
                ELSE FALSE
            END AS is_churned
    from user_sessions us
    left join (
        select *,
            row_number() OVER (PARTITION BY user_id ORDER BY start_date DESC) as rn
        from dim_plan_subscription 
        WHERE is_current = TRUE  -- filtra primero los actuales
    ) ps on us.user_id = ps.user_id 
        AND ps.rn = 1
),

--CTE final para unir con dimensiones y generar SK
final as (
    select
        {{ dbt_utils.generate_surrogate_key(['sd.session_id', 'sd.user_id', 'sd.login_date']) }} as sk_session,
        u.sk_user,
        d.sk_date,
        sd.sk_subscription,
        sd.device_type,
        sd.session_duration_seconds,
        sd.app_version,
        sd.is_churned
    from session_data sd 
    left join dim_date d on sd.login_date = d.date_actual
    left join dim_users u on sd.user_id = u.user_id
)

select * from final
