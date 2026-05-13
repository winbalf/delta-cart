select * from {{ ref('stg_olist__products') }}

union all

select * from {{ ref('stg_superstore__products') }}
