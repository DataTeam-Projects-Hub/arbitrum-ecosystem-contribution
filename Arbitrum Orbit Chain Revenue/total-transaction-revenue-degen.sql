-- https://dune.com/queries/5511609
SELECT
SUM(gas_used * gas_price) AS total_revenue_degen_raw,
SUM(gas_used * gas_price) / 1e18 AS total_revenue_degen
FROM
degen.transactions
