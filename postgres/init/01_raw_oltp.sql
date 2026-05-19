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
    ('2024-03-05', 5.02),
    ('2024-04-01', 5.08);

-- Sellers / stores
INSERT INTO raw.olist_sellers (seller_id, seller_zip_code_prefix, seller_city, seller_state) VALUES
    ('s1', '01310', 'Sao Paulo', 'SP'),
    ('s2', '30112', 'Belo Horizonte', 'MG'),
    ('s3', '40020', 'Salvador', 'BA'),
    ('s4', '60175', 'Fortaleza', 'CE'),
    ('s5', '50030', 'Recife', 'PE');

-- Customers (Olist)
INSERT INTO raw.olist_customers (
    customer_id, customer_unique_id, customer_zip_code_prefix, customer_city, customer_state,
    loyalty_tier, marketing_segment, updated_at
) VALUES
    ('oc1', 'ou1', '01310', 'Sao Paulo', 'SP', 'standard', 'value_seeker', '2024-01-01 08:00:00+00'),
    ('oc2', 'ou2', '20040', 'Rio de Janeiro', 'RJ', 'gold', 'premium', '2024-01-01 08:00:00+00'),
    ('oc3', 'ou3', '80010', 'Curitiba', 'PR', 'silver', 'mid_market', '2024-01-01 08:00:00+00'),
    ('oc4', 'ou4', '90010', 'Porto Alegre', 'RS', 'standard', 'value_seeker', '2024-01-01 08:00:00+00'),
    ('oc5', 'ou5', '70040', 'Brasilia', 'DF', 'platinum', 'enterprise', '2024-01-01 08:00:00+00'),
    ('oc6', 'ou6', '60175', 'Fortaleza', 'CE', 'gold', 'premium', '2024-01-01 08:00:00+00'),
    ('oc7', 'ou7', '50030', 'Recife', 'PE', 'standard', 'value_seeker', '2024-01-01 08:00:00+00'),
    ('oc8', 'ou8', '69005', 'Manaus', 'AM', 'silver', 'mid_market', '2024-01-01 08:00:00+00'),
    ('oc9', 'ou9', '74000', 'Goiania', 'GO', 'standard', 'high_value', '2024-01-01 08:00:00+00'),
    ('oc10', 'ou10', '30112', 'Belo Horizonte', 'MG', 'platinum', 'enterprise', '2024-01-01 08:00:00+00');

-- Products (Olist) — list_price_brl is the SCD-tracked catalog attribute alongside category
INSERT INTO raw.olist_products (
    product_id, product_category_name, product_name_length, list_price_brl, updated_at
) VALUES
    ('op1', 'electronics', 32, 120.00, '2024-01-01 08:00:00+00'),
    ('op2', 'furniture', 28, 450.00, '2024-01-01 08:00:00+00'),
    ('op3', 'health_beauty', 24, 85.00, '2024-01-01 08:00:00+00'),
    ('op4', 'sports_leisure', 36, 220.00, '2024-01-01 08:00:00+00'),
    ('op5', 'computers', 48, 1899.00, '2024-01-01 08:00:00+00'),
    ('op6', 'toys', 18, 55.00, '2024-01-01 08:00:00+00'),
    ('op7', 'housewares', 22, 78.50, '2024-01-01 08:00:00+00'),
    ('op8', 'watches_gifts', 30, 350.00, '2024-01-01 08:00:00+00'),
    ('op9', 'cool_stuff', 15, 29.90, '2024-01-01 08:00:00+00'),
    ('op10', 'auto', 40, 199.00, '2024-01-01 08:00:00+00');

-- Orders + items (BRL line amounts)
INSERT INTO raw.olist_orders (order_id, customer_id, order_status, order_purchase_timestamp, order_estimated_delivery_date) VALUES
    ('oo1', 'oc1', 'delivered', '2024-01-15 14:22:00+00', '2024-01-22'),
    ('oo2', 'oc2', 'delivered', '2024-02-10 09:05:00+00', '2024-02-18'),
    ('oo3', 'oc3', 'delivered', '2024-02-20 11:15:00+00', '2024-02-28'),
    ('oo4', 'oc4', 'delivered', '2024-03-01 16:40:00+00', '2024-03-10'),
    ('oo5', 'oc5', 'shipped', '2024-03-18 09:20:00+00', '2024-03-28'),
    ('oo6', 'oc1', 'delivered', '2024-04-02 13:05:00+00', '2024-04-12'),
    ('oo7', 'oc3', 'delivered', '2024-04-10 18:30:00+00', '2024-04-18'),
    ('oo8', 'oc6', 'delivered', '2024-02-25 10:00:00+00', '2024-03-05'),
    ('oo9', 'oc7', 'delivered', '2024-03-12 14:30:00+00', '2024-03-20'),
    ('oo10', 'oc8', 'shipped', '2024-03-22 08:45:00+00', '2024-04-01'),
    ('oo11', 'oc9', 'delivered', '2024-04-08 11:20:00+00', '2024-04-16'),
    ('oo12', 'oc10', 'delivered', '2024-04-12 16:00:00+00', '2024-04-20'),
    ('oo13', 'oc6', 'delivered', '2024-04-18 09:15:00+00', '2024-04-26'),
    ('oo14', 'oc7', 'delivered', '2024-04-20 13:40:00+00', '2024-04-28'),
    ('oo15', 'oc8', 'delivered', '2024-04-22 17:55:00+00', '2024-04-30'),
    ('oo16', 'oc9', 'delivered', '2024-04-25 10:30:00+00', '2024-05-03'),
    ('oo17', 'oc10', 'delivered', '2024-04-28 12:10:00+00', '2024-05-06');

INSERT INTO raw.olist_order_items (order_id, order_item_id, product_id, seller_id, price, freight_value) VALUES
    ('oo1', 1, 'op1', 's1', 115.50, 12.00),
    ('oo2', 1, 'op2', 's2', 430.00, 35.00),
    ('oo3', 1, 'op3', 's1', 79.90, 8.50),
    ('oo4', 1, 'op4', 's2', 210.00, 22.00),
    ('oo5', 1, 'op5', 's3', 1850.00, 95.00),
    ('oo6', 1, 'op4', 's1', 205.00, 18.00),
    ('oo7', 1, 'op2', 's2', 420.00, 30.00),
    ('oo8', 1, 'op6', 's4', 52.00, 14.00),
    ('oo9', 1, 'op7', 's5', 74.00, 11.50),
    ('oo10', 1, 'op8', 's3', 335.00, 28.00),
    ('oo11', 1, 'op9', 's1', 27.50, 6.00),
    ('oo12', 1, 'op10', 's2', 189.00, 20.00),
    ('oo13', 1, 'op1', 's4', 118.00, 15.00),
    ('oo14', 1, 'op3', 's5', 82.00, 10.00),
    ('oo15', 1, 'op5', 's3', 1900.00, 88.00),
    ('oo16', 1, 'op6', 's1', 54.00, 9.00),
    ('oo17', 1, 'op8', 's2', 340.00, 25.00);

-- Superstore division
INSERT INTO raw.superstore_customers (customer_id, customer_name, region, segment, state, loyalty_tier, updated_at) VALUES
    ('sc1', 'Nora Jones', 'West', 'Consumer', 'CA', 'standard', '2024-01-01 08:00:00+00'),
    ('sc2', 'Chris Park', 'East', 'Corporate', 'NY', 'silver', '2024-01-01 08:00:00+00'),
    ('sc3', 'Alex Rivera', 'Central', 'Home Office', 'TX', 'standard', '2024-01-01 08:00:00+00'),
    ('sc4', 'Jordan Lee', 'South', 'Consumer', 'FL', 'gold', '2024-01-01 08:00:00+00'),
    ('sc5', 'Morgan Wright', 'West', 'Corporate', 'WA', 'silver', '2024-01-01 08:00:00+00'),
    ('sc6', 'Taylor Kim', 'East', 'Consumer', 'MA', 'standard', '2024-01-01 08:00:00+00'),
    ('sc7', 'Sam Ortiz', 'Central', 'Home Office', 'IL', 'gold', '2024-01-01 08:00:00+00'),
    ('sc8', 'Riley Chen', 'South', 'Consumer', 'GA', 'standard', '2024-01-01 08:00:00+00'),
    ('sc9', 'Casey Brooks', 'West', 'Small Business', 'CO', 'platinum', '2024-01-01 08:00:00+00'),
    ('sc10', 'Drew Patel', 'East', 'Corporate', 'NJ', 'silver', '2024-01-01 08:00:00+00');

INSERT INTO raw.superstore_products (product_id, category, sub_category, list_price_usd, updated_at) VALUES
    ('sp1', 'Technology', 'Phones', 799.99, '2024-01-01 08:00:00+00'),
    ('sp2', 'Furniture', 'Chairs', 189.00, '2024-01-01 08:00:00+00'),
    ('sp3', 'Office Supplies', 'Binders', 24.99, '2024-01-01 08:00:00+00'),
    ('sp4', 'Technology', 'Accessories', 45.50, '2024-01-01 08:00:00+00'),
    ('sp5', 'Furniture', 'Tables', 299.00, '2024-01-01 08:00:00+00'),
    ('sp6', 'Office Supplies', 'Paper', 18.50, '2024-01-01 08:00:00+00'),
    ('sp7', 'Technology', 'Appliances', 1200.00, '2024-01-01 08:00:00+00'),
    ('sp8', 'Furniture', 'Bookcases', 145.00, '2024-01-01 08:00:00+00'),
    ('sp9', 'Office Supplies', 'Labels', 12.99, '2024-01-01 08:00:00+00'),
    ('sp10', 'Technology', 'Copiers', 890.00, '2024-01-01 08:00:00+00');

INSERT INTO raw.superstore_orders (order_id, customer_id, product_id, order_date, ship_mode, quantity, sales_usd, discount) VALUES
    ('so1', 'sc1', 'sp1', '2024-01-20', 'Second Class', 1, 759.99, 0.05),
    ('so2', 'sc2', 'sp2', '2024-02-12', 'Standard Class', 2, 340.00, 0.10),
    ('so3', 'sc3', 'sp3', '2024-02-22', 'Standard Class', 5, 112.45, 0.00),
    ('so4', 'sc4', 'sp4', '2024-03-08', 'First Class', 3, 129.99, 0.05),
    ('so5', 'sc1', 'sp3', '2024-03-20', 'Second Class', 2, 47.98, 0.00),
    ('so6', 'sc2', 'sp4', '2024-04-05', 'Standard Class', 4, 168.00, 0.08),
    ('so7', 'sc3', 'sp1', '2024-04-15', 'Same Day', 1, 799.99, 0.00),
    ('so8', 'sc5', 'sp5', '2024-02-28', 'Standard Class', 1, 285.00, 0.05),
    ('so9', 'sc6', 'sp6', '2024-03-14', 'Second Class', 10, 175.00, 0.00),
    ('so10', 'sc7', 'sp7', '2024-03-25', 'First Class', 1, 1140.00, 0.05),
    ('so11', 'sc8', 'sp8', '2024-04-01', 'Standard Class', 2, 276.00, 0.05),
    ('so12', 'sc9', 'sp9', '2024-04-10', 'Second Class', 20, 240.00, 0.10),
    ('so13', 'sc10', 'sp10', '2024-04-18', 'Standard Class', 1, 845.50, 0.05),
    ('so14', 'sc5', 'sp2', '2024-04-22', 'First Class', 3, 520.00, 0.08),
    ('so15', 'sc6', 'sp1', '2024-04-26', 'Same Day', 1, 779.99, 0.00),
    ('so16', 'sc7', 'sp4', '2024-04-28', 'Standard Class', 2, 86.00, 0.00),
    ('so17', 'sc8', 'sp5', '2024-04-30', 'Second Class', 1, 289.00, 0.03);
