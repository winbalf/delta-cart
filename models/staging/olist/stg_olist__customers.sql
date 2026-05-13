with source as (

    select * from {{ source('raw', 'olist_customers') }}

),

renamed as (

    select
        'olist' as source_system,
        customer_id as source_customer_id,
        ('olist:' || customer_id) as customer_nk,
        customer_unique_id,
        customer_zip_code_prefix,
        customer_city,
        customer_state,
        concat(customer_city, ', ', customer_state, ', BRA') as address_summary,
        loyalty_tier,
        marketing_segment as segment_label,
        updated_at::timestamp as updated_at

    from source

)

select * from renamed
