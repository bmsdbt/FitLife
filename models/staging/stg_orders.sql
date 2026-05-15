with source as (
    select * from {{ source('dev_raw_bronze', 'raw_orders')}}
),

-- Cargamos todas las seeds necesarias
payment_method_map as (
    select * from {{ ref('map_payment_methods')}}
),

payment_status_map as (
    select * from {{ ref('map_payment_status')}}
), 

product_category_map as (
    select * from {{ ref('mapping_product_category')}}
),

renamed as (
    select
        s.order_id,
        s.user_id,
        coalesce(pm.clean_payment_method, INITCAP(s.payment_method)) AS payment_method,
        coalesce(sm.clean_payment_status, INITCAP(s.payment_status)) AS payment_status,
        CAST(REPLACE(s.payment_amount, ',', '.') AS numeric(5,2)) as payment_amount,
        cast(s.order_date as date) as order_date,
        coalesce(pcm.clean_product_category, INITCAP(s.product_category)) AS product_category,
        s.quantity
    from source s
    LEFT JOIN payment_method_map pm 
        ON LOWER(TRIM(s.payment_method)) = pm.raw_payment_method   
    LEFT JOIN payment_status_map sm 
        ON LOWER(TRIM(s.payment_status)) = sm.raw_payment_status
    LEFT JOIN product_category_map pcm 
        ON LOWER(TRIM(s.product_category)) = pcm.raw_product_category
)

select* from renamed