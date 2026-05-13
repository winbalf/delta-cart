select
    customer_segment_at_sale,
    customer_loyalty_tier_at_sale,
    date_trunc('month', ordered_at)::date as order_month,
    sum(revenue_usd) as revenue_usd,
    sum(quantity) as units_sold

from {{ ref('fct_sales') }}

group by
    customer_segment_at_sale,
    customer_loyalty_tier_at_sale,
    date_trunc('month', ordered_at)::date
