{% macro brl_to_usd(amount_brl, brl_per_usd) %}
    ({{ amount_brl }} / nullif({{ brl_per_usd }}, 0))
{% endmacro %}
