select
    store_nk,
    source_system,
    seller_id,
    seller_zip_code_prefix,
    seller_city,
    seller_state,
    store_label

from {{ ref('stg_olist__sellers') }}
