with bounds as (

    select
        min(ordered_at::date) as min_day,
        max(ordered_at::date) as max_day

    from {{ ref('int_order_items__enriched') }}

),

spine as (

    select
        generate_series(
            (select min_day from bounds),
            (select max_day from bounds),
            interval '1 day'
        )::date as date_day

)

select
    date_day,
    extract(year from date_day)::int as year_number,
    extract(quarter from date_day)::int as quarter_of_year,
    extract(month from date_day)::int as month_of_year,
    extract(day from date_day)::int as day_of_month,
    to_char(date_day, 'YYYYMMDD')::int as date_id,
    extract(dow from date_day)::int as day_of_week

from spine
