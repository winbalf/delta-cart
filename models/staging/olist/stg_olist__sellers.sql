with source as (

    select * from {{ source('raw', 'olist_sellers') }}

),

renamed as (

    select
        'olist' as source_system,
        ('olist_seller:' || seller_id) as store_nk,
        seller_id,
        seller_zip_code_prefix,
        seller_city,
        seller_state,
        concat(seller_city, ', ', seller_state, ', BRA') as store_label

    from source

)

select * from renamed
