-- Run after initial `dbt snapshot` to simulate OLTP updates, then run `dbt snapshot` again.
-- Example: set -a; source .env; set +a && psql "postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${POSTGRES_HOST}:${POSTGRES_PORT}/${POSTGRES_DB}" -f scripts/02_oltp_day2_attribute_changes.sql

BEGIN;

-- Customer SCD drivers (tier, segment, location)
UPDATE raw.olist_customers
SET
    loyalty_tier = 'platinum',
    marketing_segment = 'high_value',
    customer_city = 'Sao Paulo',
    customer_state = 'SP',
    updated_at = '2024-03-15 10:30:00+00'::timestamptz
WHERE customer_id = 'oc1';

UPDATE raw.superstore_customers
SET
    loyalty_tier = 'gold',
    segment = 'Corporate',
    region = 'West',
    updated_at = '2024-03-15 11:00:00+00'::timestamptz
WHERE customer_id = 'sc1';

-- Product catalog price changes (separate from transactional line prices)
UPDATE raw.olist_products
SET
    list_price_brl = 139.90,
    updated_at = '2024-03-15 12:00:00+00'::timestamptz
WHERE product_id = 'op1';

UPDATE raw.superstore_products
SET
    list_price_usd = 849.99,
    updated_at = '2024-03-15 12:05:00+00'::timestamptz
WHERE product_id = 'sp1';

COMMIT;
