{{ config(
    materialized= 'table'
)}}

with orders as (
    select * from {{ ref('stg_orders')}}
),

dim_plan_subscription as (
    select * from {{ ref('dim_plan_subscription')}}
),

dim_users as (
    select * from {{ ref('dim_users')}}
),

dim_date as (
    select * from {{ ref('dim_date')}}
),

--Ingresos de orders
orders_revenue as (
    select
        o.order_id as source_id, --#Renombramos order_Id para que coincida luego con la columna equivalente en subscriptions#
        o.user_id,
        o.order_date as revenue_date, --Renombramos por la misma razón
        o.payment_method,
        o.payment_status,
        o.product_category,
        NULL as plan_name,
        NULL as sk_subscription,
        o.payment_amount as amount,
        o.quantity,
        'Order' as revenue_type
    from orders o
    where o.payment_status = 'Completed'
),

--Ingresos de subscriptions
subscriptions_revenue as (
    SELECT
        ps.subscription_id AS source_id,
        ps.user_id,
        ps.start_date AS revenue_date,
        ps.payment_method,
        ps.payment_status,
        NULL AS product_category,
        ps.plan_name,
        ps.sk_subscription,
        ps.monthly_price AS amount,
        1 AS quantity,
        'Subscription' AS revenue_type
    FROM dim_plan_subscription ps
    WHERE payment_status = 'Completed'
),

combined AS (
    SELECT * FROM orders_revenue
    UNION ALL
    SELECT * FROM subscriptions_revenue
),

final as (
    select
        {{ dbt_utils.generate_surrogate_key(['source_id', 'revenue_type', 'revenue_date']) }} as sk_revenue,
        u.sk_user,
        d.sk_date,
        c.sk_subscription,
        c.payment_method,
        c.product_category,
        c.source_id,
        c.amount,
        c.quantity,
        c.revenue_type
    from combined c
    left join dim_users u on c.user_id = u.user_id 
    left join dim_date d on c.revenue_date = d.date_actual 
)

select * from final