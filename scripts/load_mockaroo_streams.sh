#!/usr/bin/env bash
# Append Mockaroo CSV exports into raw stream tables (idempotent event_id PK).
# Usage:
#   ./scripts/load_mockaroo_streams.sh
#   ./scripts/load_mockaroo_streams.sh /path/to/customers.csv /path/to/products.csv
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ -f "$ROOT/.env" ]]; then
  set -a; source "$ROOT/.env"; set +a
fi

CUSTOMER_CSV="${1:-$ROOT/mockaroo/samples/customer_attribute_stream.csv}"
PRODUCT_CSV="${2:-$ROOT/mockaroo/samples/product_attribute_stream.csv}"

PGURI="${PGURI:-postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${POSTGRES_HOST:-localhost}:${POSTGRES_PORT:-5433}/${POSTGRES_DB}}"

if [[ ! -f "$CUSTOMER_CSV" ]]; then
  echo "Customer CSV not found: $CUSTOMER_CSV" >&2
  exit 1
fi

if [[ ! -f "$PRODUCT_CSV" ]]; then
  echo "Product CSV not found: $PRODUCT_CSV" >&2
  exit 1
fi

CUSTOMER_CSV_ABS="$(realpath "$CUSTOMER_CSV")"
PRODUCT_CSV_ABS="$(realpath "$PRODUCT_CSV")"

echo "Loading customers from $CUSTOMER_CSV_ABS"
psql "$PGURI" -v ON_ERROR_STOP=1 -c "\copy raw.mockaroo_customer_attribute_stream (event_id, customer_nk, source_customer_id, customer_unique_id, customer_zip_code_prefix, customer_city, customer_state, address_summary, loyalty_tier, segment_label, updated_at) FROM '$CUSTOMER_CSV_ABS' CSV HEADER"

echo "Loading products from $PRODUCT_CSV_ABS"
psql "$PGURI" -v ON_ERROR_STOP=1 -c "\copy raw.mockaroo_product_attribute_stream (event_id, product_nk, source_product_id, category_name, product_name_length, list_price_local, local_currency, updated_at) FROM '$PRODUCT_CSV_ABS' CSV HEADER"

echo "Done. Run dbt snapshot (or scripts/recurring_snapshot_job.sh) to accumulate SCD2 versions."
