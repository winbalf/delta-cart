-- Run after dbt build. Connect to deltacart and set search_path, or query with schema prefix.
-- psql "$PGURI" -f analyses/explore_fct_sales_changes.sql

-- 1) Baseline: all fact rows (expect 34 lines after scripts/03_expand_seed_data.sql + dbt build)
select
    order_line_nk,
    source_system,
    ordered_at::date,
    revenue_usd,
    quantity,
    customer_segment_at_sale,
    customer_loyalty_tier_at_sale,
    product_category_at_sale,
    catalog_list_price_local_at_sale
from analytics.fct_sales
order by ordered_at, order_line_nk;

-- 2) Rollups used by fct_sales_by_segment
select *
from analytics.fct_sales_by_segment
order by order_month, customer_segment_at_sale;

-- 3) After scripts/02_oltp_day2_attribute_changes.sql + dbt snapshot + dbt run:
--    Row count stays the same; segment/tier/category-at-sale on OLD orders can change
--    if ordered_at falls inside the new SCD validity window.
-- Compare oc1 / sc1 lines before and after the day-2 script.

-- 4) After changing ONLY line revenue (no snapshot needed):
--    UPDATE raw.olist_order_items SET price = 200 WHERE order_id = 'oo1' AND order_item_id = 1;
--    UPDATE raw.superstore_orders SET sales_usd = 900, discount = 0 WHERE order_id = 'so1';
--    then: dbt run --select int_order_items__enriched+ fct_sales fct_sales_by_segment

-- 5) After INSERTing a new order (increases row count):
--    Use scripts/03_expand_seed_data.sql or add your own oo8/so8 rows, then dbt run.
