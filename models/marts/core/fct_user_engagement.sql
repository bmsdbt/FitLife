{{ config(
    materialized= 'incremental',
    unique_key= 'sk_activity',
    incremental_strategy='merge'
)}}

--CTEs de fuentes para cargar las tablas que necesito
with dim_date as (
    select * from {{ ref('dim_date')}}
),

dim_users as (
    select * from {{ ref('dim_users')}}
),

dim_plan_subscription as (
    select * from {{ ref('dim_plan_subscription')}}
),

activity_logs as (
    select * from {{ ref('stg_activity_logs')}}
),

--CTE de transfromación para calcular métricas y filtrar. Los cálculos van antes de los joins
activity_data as (
    select
        al.activity_id,
        al.user_id,
        al.activity_type,
        al.duration_minutes,
        al.calories_burned,
        al.activity_date
    from activity_logs al

    -- Filtro para traer los datos nuevos
    {% if is_incremental() %}
        where al.activity_date >= (select max(activity_date) from {{ this }})
    {% endif %}
),

--CTE final para unir con dimensiones y generar SK
final as (
    select
        {{ dbt_utils.generate_surrogate_key(['ad.activity_id'])}} as sk_activity,
        u.sk_user,
        d.sk_date,
        ps.sk_subscription,
        ad.activity_type,
        ad.duration_minutes,
        ad.calories_burned,
        ad.activity_date -- Esta columna la añado para soportar el filtro de la incremental
    from activity_data ad 
    left join dim_date d on ad.activity_date = d.date_actual
    left join dim_users u on ad.user_id = u.user_id
    left join dim_plan_subscription ps 
        on ad.user_id = ps.user_id
        and ad.activity_date >= ps.start_date
        and (ad.activity_date <= ps.end_date or ps.end_date is null)
        and ps.is_current = TRUE 
    --Ponemos esto para matar los duplicados del JOIN
    qualify row_number() over(partition by ad.activity_id order by ps.start_date desc) = 1
)
    

select * from final