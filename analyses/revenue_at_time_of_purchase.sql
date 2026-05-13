-- Revenue attributed to the customer segment at time of purchase (SCD2 / snapshot PIT join).

select
    order_line_nk,
    ordered_at,
    customer_segment_at_sale,
    customer_loyalty_tier_at_sale,
    revenue_usd

from {{ ref('fct_sales') }}

order by ordered_at, order_line_nk
