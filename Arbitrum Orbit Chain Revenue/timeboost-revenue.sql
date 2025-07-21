-- https://dune.com/queries/5512383/8978856
SELECT
  block_date,
  daily_timeboost_extra_paid_degen,
  SUM(daily_timeboost_extra_paid_degen) OVER (ORDER BY block_date ASC) AS cumulative_timeboost_extra_paid_degen
FROM (
  SELECT
    block_date,
    SUM(
      CASE
        WHEN success = TRUE
        THEN TRY_CAST(gas_used AS DECIMAL) * TRY_CAST(priority_fee_per_gas AS DECIMAL)
        ELSE 0
      END
    ) / 1e18 AS daily_timeboost_extra_paid_degen
  FROM degen.transactions
  GROUP BY block_date
) a
ORDER BY block_date;
