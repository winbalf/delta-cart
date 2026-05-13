with source as (

    select * from {{ source('raw', 'superstore_customers') }}

),

renamed as (

    select
        'superstore' as source_system,
        customer_id as source_customer_id,
        ('superstore:' || customer_id) as customer_nk,
        cast(null as text) as customer_unique_id,
        cast(null as text) as customer_zip_code_prefix,
        cast(null as text) as customer_city,
        state as customer_state,
        concat(customer_name, ' — ', region, ', USA') as address_summary,
        loyalty_tier,
        segment as segment_label,
        updated_at::timestamp as updated_at

    from source

)

select * from renamed
