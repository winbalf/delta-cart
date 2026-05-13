with source as (

    select * from {{ source('raw', 'olist_orders') }}

),

renamed as (

    select
        order_id,
        customer_id,
        order_status,
        order_purchase_timestamp,
        order_estimated_delivery_date

    from source

)

select * from renamed
