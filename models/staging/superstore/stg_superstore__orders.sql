with source as (

    select * from {{ source('raw', 'superstore_orders') }}

),

renamed as (

    select
        order_id,
        customer_id,
        product_id,
        order_date,
        ship_mode,
        quantity,
        sales_usd,
        discount

    from source

)

select * from renamed
