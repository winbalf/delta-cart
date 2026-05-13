-- Compile with `dbt compile` then run the compiled SQL in your SQL client, or use `dbt show`.
-- Demonstrates multiple active windows per natural customer key after a second snapshot run.

select
    customer_nk,
    valid_from,
    valid_to,
    loyalty_tier,
    segment_label,
    address_summary

from {{ ref('dim_customers') }}

order by customer_nk, valid_from
