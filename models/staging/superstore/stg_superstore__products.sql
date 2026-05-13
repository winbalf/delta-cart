with source as (

    select * from {{ source('raw', 'superstore_products') }}

),

renamed as (

    select
        'superstore' as source_system,
        product_id as source_product_id,
        ('superstore:' || product_id) as product_nk,
        category as category_name,
        cast(null as int) as product_name_length,
        list_price_usd as list_price_local,
        'USD' as local_currency,
        updated_at::timestamp as updated_at

    from source

)

select * from renamed
