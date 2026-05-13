with combined as (

    select * from {{ ref('int_customers__unioned') }}

    union all

    select * from {{ ref('stg_mockaroo__customer_attribute_stream') }}

),

ranked as (

    select
        combined.*,
        row_number() over (
            partition by customer_nk
            order by
                updated_at desc,
                case source_system
                    when 'mockaroo' then 3
                    when 'olist' then 2
                    when 'superstore' then 1
                    else 0
                end desc
        ) as _feed_rank

    from combined

)

select
    source_system,
    source_customer_id,
    customer_nk,
    customer_unique_id,
    customer_zip_code_prefix,
    customer_city,
    customer_state,
    address_summary,
    loyalty_tier,
    segment_label,
    updated_at

from ranked

where _feed_rank = 1
