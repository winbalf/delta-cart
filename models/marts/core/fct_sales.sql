with lines as (

    select * from {{ ref('int_order_items__enriched') }}

),

customers as (

    select * from {{ ref('dim_customers') }}

),

products as (

    select * from {{ ref('dim_products') }}

),

dates as (

    select * from {{ ref('dim_date') }}

),

pit_customers as (

    select
        lines.*,
        customers.customer_sk,
        customers.segment_label as customer_segment_at_sale,
        customers.loyalty_tier as customer_loyalty_tier_at_sale

    from lines
    inner join customers
        on customers.customer_nk = lines.customer_nk
        and lines.ordered_at >= customers.valid_from
        and (customers.valid_to is null or lines.ordered_at < customers.valid_to)

),

pit_products as (

    select
        pc.*,
        products.product_sk,
        products.category_name as product_category_at_sale,
        products.list_price_local as catalog_list_price_local_at_sale,
        products.local_currency as catalog_price_currency_at_sale

    from pit_customers as pc
    inner join products
        on products.product_nk = pc.product_nk
        and pc.ordered_at >= products.valid_from
        and (products.valid_to is null or pc.ordered_at < products.valid_to)

),

with_date as (

    select
        pit_products.*,
        dates.date_id as order_date_id

    from pit_products
    inner join dates
        on dates.date_day = pit_products.ordered_at::date

),

final as (

    select
        {{ dbt_utils.generate_surrogate_key(['order_line_nk']) }} as sales_fact_sk,
        order_line_nk,
        source_system,
        ordered_at,
        order_date_id,
        customer_sk,
        product_sk,
        store_nk,
        revenue_usd,
        quantity,
        customer_segment_at_sale,
        customer_loyalty_tier_at_sale,
        product_category_at_sale,
        catalog_list_price_local_at_sale,
        catalog_price_currency_at_sale

    from with_date

)

select * from final
