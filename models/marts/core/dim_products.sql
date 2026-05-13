select
    dbt_scd_id as product_sk,
    product_nk,
    source_system,
    source_product_id,
    category_name,
    list_price_local,
    local_currency,
    dbt_valid_from as valid_from,
    dbt_valid_to as valid_to

from {{ ref('snap_products') }}
