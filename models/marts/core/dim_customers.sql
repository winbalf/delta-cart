select
    dbt_scd_id as customer_sk,
    customer_nk,
    source_system,
    source_customer_id,
    segment_label,
    loyalty_tier,
    address_summary,
    customer_city,
    customer_state,
    dbt_valid_from as valid_from,
    dbt_valid_to as valid_to

from {{ ref('snap_customers') }}
