{{ config(
    materialized= 'table'
)}}

with source_subscription as(
    select * from {{ ref('snapshot_plan_subscription') }}
),

final_subscription as (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['subscription_id', 'user_id']) }} as sk_subscription,
        subscription_id,
        user_id,
        plan_name,
        monthly_price,
        start_date,
        end_date,
        status,
        payment_method,
        payment_status,
        -- Columnas del snapshot para historial
        dbt_valid_from,
        dbt_valid_to,
        -- Si dbt_valid_to es NULL significa que es el registro actual
        CASE WHEN dbt_valid_to IS NULL THEN TRUE 
            ELSE FALSE 
        END AS is_current
    from source_subscription
)

select * from final_subscription