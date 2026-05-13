# delta-cart

Transactional retail OLTP simulation in Postgres, plus a **dbt** star-schema warehouse with **SCD Type 2** dimensions (dbt snapshots) and **point-in-time (PIT)** joins on `fct_sales`. The story you can tell in interviews: a Brazil-based retailer (Olist-shaped data) acquires a US division (Superstore-shaped data); you unify keys, normalize currency, and attribute revenue to **customer segment at time of purchase**, not “segment today.”

## Architecture

```mermaid
flowchart TB
  subgraph oltp [OLTP Postgres raw]
    OC[olist_customers]
    OO[olist_orders]
    OI[olist_order_items]
    OP[olist_products]
    SC[superstore_customers]
    SO[superstore_orders]
    SP[superstore_products]
    FX[exchange_rates]
    MR_C[mockaroo_customer_attribute_stream]
    MR_P[mockaroo_product_attribute_stream]
  end

  subgraph dbt [dbt warehouse]
    STG[staging olist + superstore + mockaroo]
    INT[int unions + int_*__snapshot_feed + int_order_items__enriched]
    SNAP[snap_customers + snap_products]
    DIM[dim_customers + dim_products + dim_date + dim_stores]
    FCT[fct_sales + fct_sales_by_segment]
  end

  oltp --> STG --> INT --> SNAP --> DIM --> FCT
```

- **OLTP**: `raw` schema from Docker init: `postgres/init/01_raw_oltp.sql` (core retail tables) and `postgres/init/02_mockaroo_stream_tables.sql` (empty append-only Mockaroo landing tables + indexes).
- **Staging**: typed, renamed, prefixed natural keys (`olist:…`, `superstore:…`) to avoid collisions across systems.
- **Intermediate**: `int_customers__unioned`, `int_products__unioned`, `int_order_items__enriched` (BRL → USD using `raw.exchange_rates` with a variable fallback). **`int_customers__snapshot_feed`** and **`int_products__snapshot_feed`** merge OLTP/Superstore with **Mockaroo append-only streams** by taking the row with the latest `updated_at` per natural key (ties broken with `mockaroo` > `olist` > `superstore`).
- **Snapshots**: `snap_customers` and `snap_products` read the `*_snapshot_feed` models and use the **timestamp** strategy on `updated_at` (cast to `timestamp` for clean Postgres snapshot metadata).
- **Marts**: conformed dimensions on top of snapshots; `fct_sales` joins facts to dims where `ordered_at ∈ [valid_from, valid_to)`.

## Quickstart

1. **Start Postgres**

   ```bash
   docker compose up -d
   ```

2. **Configure environment and dbt**

   ```bash
   cp .env.example .env        # edit credentials if needed
   cp profiles.yml.example profiles.yml
   ```

   Both `profiles.yml` and the shell scripts read credentials from `.env` via `env_var()` (dbt) or `source .env` (bash). Source the file with `set -a` so variables are exported:

   ```bash
   set -a; source .env; set +a
   ```

   Defaults match Docker: host `localhost`, port `5433`, database `deltacart`, schema `analytics`.

3. **Install packages and build**

   ```bash
   set -a; source .env; set +a
   export DBT_PROFILES_DIR="$(pwd)"
   dbt deps
   dbt build
   ```

   If you do not have dbt installed globally, one option is:

   ```bash
   set -a; source .env; set +a
   uvx --from dbt-postgres dbt deps
   uvx --from dbt-postgres dbt build --profiles-dir "$(pwd)"
   ```

## Demonstrating SCD Type 2 (two snapshot runs)

1. Initial build (already creates first snapshot versions).

   ```bash
   dbt build
   ```

2. Simulate **day-two OLTP attribute changes** (tier, segment, catalog list prices):

   ```bash
   set -a; source .env; set +a
   psql "postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${POSTGRES_HOST}:${POSTGRES_PORT}/${POSTGRES_DB}" \
     -f scripts/02_oltp_day2_attribute_changes.sql
   ```

3. **Capture new slowly changing rows**:

   ```bash
   dbt snapshot
   dbt run --select dim_customers dim_products fct_sales fct_sales_by_segment
   ```

4. Inspect history vs PIT attribution:

   ```sql
   SELECT customer_nk, valid_from, valid_to, segment_label, loyalty_tier
   FROM analytics.dim_customers
   ORDER BY customer_nk, valid_from;

   SELECT order_line_nk, ordered_at, customer_segment_at_sale, customer_loyalty_tier_at_sale, revenue_usd
   FROM analytics.fct_sales
   ORDER BY ordered_at;
   ```

   After the day-two script, customers like `olist:oc1` have a **new** current row (e.g. platinum / high_value), while January orders still resolve to **value_seeker / standard** via the PIT join.

## OLAP analyses

- `analyses/scd2_history_demo.sql` — version history from `dim_customers`.
- `analyses/revenue_at_time_of_purchase.sql` — revenue with **segment at sale**.

Compile and preview:

```bash
dbt compile --select analyses/revenue_at_time_of_purchase
dbt show --inline "select * from {{ ref('fct_sales') }} limit 20"
```

## Mockaroo streams and recurring jobs

1. **Schema in Postgres** — `postgres/init/02_mockaroo_stream_tables.sql` creates append-only `raw.mockaroo_customer_attribute_stream` and `raw.mockaroo_product_attribute_stream` (also run once on older databases that were created before this file existed):

   ```bash
   set -a; source .env; set +a
   psql "postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${POSTGRES_HOST}:${POSTGRES_PORT}/${POSTGRES_DB}" \
     -f postgres/init/02_mockaroo_stream_tables.sql
   ```

2. **Define datasets in Mockaroo** — Field lists for CSV export live in `mockaroo/mockaroo_customer_stream.fields.txt` and `mockaroo/mockaroo_product_stream.fields.txt`. Use a new **`event_id`** per generated row so loads stay idempotent with the tables’ primary keys.

3. **Land CSVs into Postgres** — Example (defaults to bundled samples):

   ```bash
   ./scripts/load_mockaroo_streams.sh
   ./scripts/load_mockaroo_streams.sh ./exports/mockaroo_customers.csv ./exports/mockaroo_products.csv
   ```

   Override the connection string if needed: `PGURI=postgresql://user:pass@host:5432/dbname ./scripts/load_mockaroo_streams.sh …`

4. **Accumulate SCD2 in snapshots** — After each load (or on a schedule), run:

   ```bash
   ./scripts/recurring_snapshot_job.sh
   ```

   That script `\copy`s into `raw`, runs `dbt snapshot` for `snap_customers` / `snap_products`, then rebuilds `dim_*` and `fct_sales*`. Wire the same steps into **cron**, **Airflow**, **Dagster**, or a **self-hosted GitHub Actions** runner that can reach Postgres.

5. **Optional automation API** — Mockaroo’s REST API can generate CSV/JSON on a schedule; write the response to disk and call `load_mockaroo_streams.sh` (see [Mockaroo API](https://www.mockaroo.com/api/docs)).

## Scaling out with real Kaggle data

- Replace or bulk-load `raw.*` tables from [Brazilian E-Commerce (Olist)](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) and [Superstore](https://www.kaggle.com/datasets/vivek468/superstore-dataset-final). Keep the **natural key prefixes** (`olist:`, `superstore:`) in staging so merges stay collision-free.
- Keep Mockaroo keys aligned with those prefixes so `int_*__snapshot_feed` and snapshots stay consistent.

`seeds/` contains tiny **header-compatible** CSV examples for dbt-only demos; **Mockaroo production-style streams** live under `mockaroo/samples/` and load into **`raw.mockaroo_*`** via `scripts/load_mockaroo_streams.sh`.

## Project layout

| Path | Role |
|------|------|
| `postgres/init/` | OLTP DDL + seed inserts into `raw` |
| `scripts/02_oltp_day2_attribute_changes.sql` | Controlled updates to exercise snapshots |
| `models/staging/` | Source-specific cleaning |
| `models/intermediate/` | Union + enriched order lines |
| `snapshots/` | SCD Type 2 via dbt snapshots |
| `models/marts/core/` | Star schema (dims + `fct_sales`) |
| `models/marts/marketing/` | `fct_sales_by_segment` rollups |
| `macros/convert_currency.sql` | `brl_to_usd` helper |
| `analyses/` | Interview-friendly example queries |

Add a `LICENSE` file when you publish the repo if you need explicit terms.
