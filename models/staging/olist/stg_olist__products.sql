with source as (

    select * from {{ source('raw', 'olist_products') }}

),

renamed as (

    select
        'olist' as source_system,
        product_id as source_product_id,
        ('olist:' || product_id) as product_nk,
        product_category_name as category_name,
        product_name_length,
        list_price_brl as list_price_local,
        'BRL' as local_currency,
        updated_at::timestamp as updated_at

    from source

)

select * from renamed
