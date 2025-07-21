-- https://dune.com/queries/5511611/8976764
SELECT
  block_date,
  SUM(gas_used * gas_price) / 1e18 AS total_revenue_degen,
  SUM(SUM(gas_used * gas_price) / 1e18) OVER (ORDER BY block_date ASC) AS cumulative_revenue_degen
FROM
  degen.transactions
GROUP BY
  block_date
ORDER BY
  block_date ASC
