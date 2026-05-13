select * from {{ ref('stg_olist__customers') }}

union all

select * from {{ ref('stg_superstore__customers') }}
