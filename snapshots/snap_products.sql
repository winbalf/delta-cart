{% snapshot snap_products %}

{{
    config(
      unique_key='product_nk',
      strategy='timestamp',
      updated_at='updated_at',
      invalidate_hard_deletes=True,
    )
}}

select * from {{ ref('int_products__snapshot_feed') }}

{% endsnapshot %}
