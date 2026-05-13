{% snapshot snap_customers %}

{{
    config(
      unique_key='customer_nk',
      strategy='timestamp',
      updated_at='updated_at',
      invalidate_hard_deletes=True,
    )
}}

select * from {{ ref('int_customers__snapshot_feed') }}

{% endsnapshot %}
