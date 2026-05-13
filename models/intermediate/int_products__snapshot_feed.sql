with combined as (

    select * from {{ ref('int_products__unioned') }}

    union all

    select * from {{ ref('stg_mockaroo__product_attribute_stream') }}

),

ranked as (

    select
        combined.*,
        row_number() over (
            partition by product_nk
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
    source_product_id,
    product_nk,
    category_name,
    product_name_length,
    list_price_local,
    local_currency,
    updated_at

from ranked

where _feed_rank = 1
