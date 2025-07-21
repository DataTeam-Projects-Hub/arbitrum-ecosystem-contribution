-- https://dune.com/queries/5511664/8976794
SELECT
  block_date,
  SUM(gas_used * gas_price) / 1e18 AS daily_revenue_degen,
  SUM(SUM(gas_used * gas_price)) OVER (PARTITION BY YEAR(block_date), WEEK(block_date) ORDER BY block_date) / 1e18 AS weekly_revenue_degen,
  SUM(SUM(gas_used * gas_price)) OVER (PARTITION BY YEAR(block_date), MONTH(block_date) ORDER BY block_date) / 1e18 AS monthly_revenue_degen
FROM degen.transactions
GROUP BY
  block_date
ORDER BY
  block_date