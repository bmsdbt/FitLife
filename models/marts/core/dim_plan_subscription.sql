{{ config(
    materialized= 'table'
)}}

with source_subscription as(
    select * from {{ ref('stg_subscriptions') }}
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
        payment_status
    from source_subscription
)

select * from final_subscription