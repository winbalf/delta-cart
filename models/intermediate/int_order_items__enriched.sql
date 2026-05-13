with rates as (

    select * from {{ source('raw', 'exchange_rates') }}

),

olist_lines as (

    select
        concat('olist:', oi.order_id, ':', cast(oi.order_item_id as text)) as order_line_nk,
        'olist' as source_system,
        o.order_purchase_timestamp as ordered_at,
        ('olist:' || o.customer_id) as customer_nk,
        ('olist:' || oi.product_id) as product_nk,
        ('olist_seller:' || oi.seller_id) as store_nk,
        oi.price + oi.freight_value as line_revenue_brl,
        1::bigint as quantity

    from {{ ref('stg_olist__order_items') }} as oi
    inner join {{ ref('stg_olist__orders') }} as o
        on oi.order_id = o.order_id

),

olist_with_fx as (

    select
        ol.*,
        coalesce(
            (
                select r.brl_per_usd
                from rates as r
                where r.rate_date <= ol.ordered_at::date
                order by r.rate_date desc
                limit 1
            ),
            {{ var("default_brl_per_usd") }}
        ) as brl_per_usd

    from olist_lines as ol

),

olist_normalized as (

    select
        order_line_nk,
        source_system,
        ordered_at,
        customer_nk,
        product_nk,
        store_nk,
        {{ brl_to_usd('line_revenue_brl', 'brl_per_usd') }} as revenue_usd,
        quantity

    from olist_with_fx

),

super_lines as (

    select
        concat('superstore:', so.order_id) as order_line_nk,
        'superstore' as source_system,
        (so.order_date::timestamp at time zone 'UTC') as ordered_at,
        ('superstore:' || so.customer_id) as customer_nk,
        ('superstore:' || so.product_id) as product_nk,
        cast(null as text) as store_nk,
        so.sales_usd * (1::numeric - so.discount) as revenue_usd,
        cast(so.quantity as bigint) as quantity

    from {{ ref('stg_superstore__orders') }} as so

),

unioned as (

    select * from olist_normalized
    union all
    select * from super_lines

)

select * from unioned
