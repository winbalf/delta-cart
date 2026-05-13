-- Append-only attribute streams (Mockaroo CSV lands here between dbt runs).
-- Latest row per natural key is resolved in int_*__snapshot_feed for dbt snapshots.
-- Keep this file DDL-only; load sample or generated rows via scripts/load_mockaroo_streams.sh.

CREATE TABLE IF NOT EXISTS raw.mockaroo_customer_attribute_stream (
    event_id TEXT PRIMARY KEY,
    customer_nk TEXT NOT NULL,
    source_customer_id TEXT,
    customer_unique_id TEXT,
    customer_zip_code_prefix TEXT,
    customer_city TEXT,
    customer_state TEXT,
    address_summary TEXT,
    loyalty_tier TEXT,
    segment_label TEXT,
    updated_at TIMESTAMP NOT NULL,
    loaded_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS raw.mockaroo_product_attribute_stream (
    event_id TEXT PRIMARY KEY,
    product_nk TEXT NOT NULL,
    source_product_id TEXT,
    category_name TEXT,
    product_name_length INT,
    list_price_local NUMERIC(12, 2),
    local_currency TEXT,
    updated_at TIMESTAMP NOT NULL,
    loaded_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_mockaroo_customer_nk_updated
    ON raw.mockaroo_customer_attribute_stream (customer_nk, updated_at DESC);

CREATE INDEX IF NOT EXISTS idx_mockaroo_product_nk_updated
    ON raw.mockaroo_product_attribute_stream (product_nk, updated_at DESC);
