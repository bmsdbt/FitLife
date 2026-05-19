{% snapshot snapshot_plan_subscription %}

    {{
        config(
            unique_key='subscription_id',
            strategy='check',
            check_cols=['monthly_price', 'status', 'plan_name']
        )
    }}

    SELECT * FROM {{ ref('stg_subscriptions') }}

{% endsnapshot %}