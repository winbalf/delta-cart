with source as (

    select * from {{ source('raw', 'mockaroo_product_attribute_stream') }}

),

normalized as (

    select
        'mockaroo' as source_system,
        coalesce(source_product_id, split_part(product_nk, ':', 2)) as source_product_id,
        product_nk,
        category_name,
        product_name_length,
        list_price_local,
        local_currency,
        updated_at::timestamp as updated_at

    from source

)

select * from normalized
