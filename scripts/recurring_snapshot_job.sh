#!/usr/bin/env bash
# Recurring job: land Mockaroo CSVs → Postgres → dbt snapshots → rebuild dims/facts.
# Schedule with cron, Airflow, Dagster, GitHub Actions (self-hosted runner with DB access), etc.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ -f "$ROOT/.env" ]]; then
  set -a; source "$ROOT/.env"; set +a
fi

export DBT_PROFILES_DIR="${DBT_PROFILES_DIR:-$ROOT}"

CUSTOMER_CSV="${1:-$ROOT/mockaroo/samples/customer_attribute_stream.csv}"
PRODUCT_CSV="${2:-$ROOT/mockaroo/samples/product_attribute_stream.csv}"

"$ROOT/scripts/load_mockaroo_streams.sh" "$CUSTOMER_CSV" "$PRODUCT_CSV"

cd "$ROOT"

if command -v dbt >/dev/null 2>&1; then
  DBT=(dbt)
else
  DBT=(uvx --from dbt-postgres dbt)
fi

"${DBT[@]}" snapshot --profiles-dir "$ROOT" --select snap_customers snap_products
"${DBT[@]}" run --profiles-dir "$ROOT" --select dim_customers dim_products fct_sales fct_sales_by_segment

echo "Recurring warehouse refresh complete."
