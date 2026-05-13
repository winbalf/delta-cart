with source as (

    select * from {{ source('raw', 'mockaroo_customer_attribute_stream') }}

),

normalized as (

    select
        'mockaroo' as source_system,
        coalesce(source_customer_id, split_part(customer_nk, ':', 2)) as source_customer_id,
        customer_nk,
        customer_unique_id,
        customer_zip_code_prefix,
        customer_city,
        customer_state,
        address_summary,
        loyalty_tier,
        segment_label,
        updated_at::timestamp as updated_at

    from source

)

select * from normalized
