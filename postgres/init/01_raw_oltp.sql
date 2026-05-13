-- OLTP simulation: raw landing zone (Brazil Olist-style + US Superstore-style)
CREATE SCHEMA IF NOT EXISTS raw;

-- Olist-style entities
CREATE TABLE raw.olist_customers (
    customer_id TEXT PRIMARY KEY,
    customer_unique_id TEXT,
    customer_zip_code_prefix TEXT,
    customer_city TEXT,
    customer_state TEXT,
    loyalty_tier TEXT NOT NULL DEFAULT 'standard',
    marketing_segment TEXT NOT NULL DEFAULT 'unknown',
    updated_at TIMESTAMPTZ NOT NULL DEFAULT ('2024-01-01 08:00:00+00'::timestamptz)
);

CREATE TABLE raw.olist_sellers (
    seller_id TEXT PRIMARY KEY,
    seller_zip_code_prefix TEXT,
    seller_city TEXT,
    seller_state TEXT
);

CREATE TABLE raw.olist_products (
    product_id TEXT PRIMARY KEY,
    product_category_name TEXT,
    product_name_length INT,
    list_price_brl NUMERIC(12, 2) NOT NULL DEFAULT 0,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT ('2024-01-01 08:00:00+00'::timestamptz)
);

CREATE TABLE raw.olist_orders (
    order_id TEXT PRIMARY KEY,
    customer_id TEXT NOT NULL REFERENCES raw.olist_customers (customer_id),
    order_status TEXT,
    order_purchase_timestamp TIMESTAMPTZ,
    order_estimated_delivery_date DATE
);

CREATE TABLE raw.olist_order_items (
    order_id TEXT NOT NULL REFERENCES raw.olist_orders (order_id),
    order_item_id INT NOT NULL,
    product_id TEXT NOT NULL REFERENCES raw.olist_products (product_id),
    seller_id TEXT NOT NULL REFERENCES raw.olist_sellers (seller_id),
    price NUMERIC(12, 2) NOT NULL,
    freight_value NUMERIC(12, 2) NOT NULL,
    PRIMARY KEY (order_id, order_item_id)
);

-- Superstore-style (US division after acquisition)
CREATE TABLE raw.superstore_customers (
    customer_id TEXT PRIMARY KEY,
    customer_name TEXT,
    region TEXT,
    segment TEXT,
    state TEXT,
    loyalty_tier TEXT NOT NULL DEFAULT 'standard',
    updated_at TIMESTAMPTZ NOT NULL DEFAULT ('2024-01-01 08:00:00+00'::timestamptz)
);

CREATE TABLE raw.superstore_products (
    product_id TEXT PRIMARY KEY,
    category TEXT,
    sub_category TEXT,
    list_price_usd NUMERIC(12, 2) NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT ('2024-01-01 08:00:00+00'::timestamptz)
);

CREATE TABLE raw.superstore_orders (
    order_id TEXT PRIMARY KEY,
    customer_id TEXT NOT NULL REFERENCES raw.superstore_customers (customer_id),
    product_id TEXT NOT NULL REFERENCES raw.superstore_products (product_id),
    order_date DATE NOT NULL,
    ship_mode TEXT,
    quantity INT NOT NULL,
    sales_usd NUMERIC(12, 2) NOT NULL,
    discount NUMERIC(12, 4) NOT NULL DEFAULT 0
);

-- Reference FX for macro demos
CREATE TABLE raw.exchange_rates (
    rate_date DATE PRIMARY KEY,
    brl_per_usd NUMERIC(12, 6) NOT NULL
);

INSERT INTO raw.exchange_rates (rate_date, brl_per_usd) VALUES
    ('2024-01-15', 4.95),
    ('2024-02-10', 4.98),
    ('2024-03-05', 5.02);

-- Sellers / stores
INSERT INTO raw.olist_sellers (seller_id, seller_zip_code_prefix, seller_city, seller_state) VALUES
    ('s1', '01310', 'Sao Paulo', 'SP'),
    ('s2', '30112', 'Belo Horizonte', 'MG');

-- Customers (Olist)
INSERT INTO raw.olist_customers (
    customer_id, customer_unique_id, customer_zip_code_prefix, customer_city, customer_state,
    loyalty_tier, marketing_segment, updated_at
) VALUES
    ('oc1', 'ou1', '01310', 'Sao Paulo', 'SP', 'standard', 'value_seeker', '2024-01-01 08:00:00+00'),
    ('oc2', 'ou2', '20040', 'Rio de Janeiro', 'RJ', 'gold', 'premium', '2024-01-01 08:00:00+00');

-- Products (Olist) — list_price_brl is the SCD-tracked catalog attribute alongside category
INSERT INTO raw.olist_products (
    product_id, product_category_name, product_name_length, list_price_brl, updated_at
) VALUES
    ('op1', 'electronics', 32, 120.00, '2024-01-01 08:00:00+00'),
    ('op2', 'furniture', 28, 450.00, '2024-01-01 08:00:00+00');

-- Orders + items (BRL line amounts)
INSERT INTO raw.olist_orders (order_id, customer_id, order_status, order_purchase_timestamp, order_estimated_delivery_date) VALUES
    ('oo1', 'oc1', 'delivered', '2024-01-15 14:22:00+00', '2024-01-22'),
    ('oo2', 'oc2', 'delivered', '2024-02-10 09:05:00+00', '2024-02-18');

INSERT INTO raw.olist_order_items (order_id, order_item_id, product_id, seller_id, price, freight_value) VALUES
    ('oo1', 1, 'op1', 's1', 115.50, 12.00),
    ('oo2', 1, 'op2', 's2', 430.00, 35.00);

-- Superstore division
INSERT INTO raw.superstore_customers (customer_id, customer_name, region, segment, state, loyalty_tier, updated_at) VALUES
    ('sc1', 'Nora Jones', 'West', 'Consumer', 'CA', 'standard', '2024-01-01 08:00:00+00'),
    ('sc2', 'Chris Park', 'East', 'Corporate', 'NY', 'silver', '2024-01-01 08:00:00+00');

INSERT INTO raw.superstore_products (product_id, category, sub_category, list_price_usd, updated_at) VALUES
    ('sp1', 'Technology', 'Phones', 799.99, '2024-01-01 08:00:00+00'),
    ('sp2', 'Furniture', 'Chairs', 189.00, '2024-01-01 08:00:00+00');

INSERT INTO raw.superstore_orders (order_id, customer_id, product_id, order_date, ship_mode, quantity, sales_usd, discount) VALUES
    ('so1', 'sc1', 'sp1', '2024-01-20', 'Second Class', 1, 759.99, 0.05),
    ('so2', 'sc2', 'sp2', '2024-02-12', 'Standard Class', 2, 340.00, 0.10);
