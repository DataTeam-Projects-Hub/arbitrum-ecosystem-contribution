SELECT
  t.block_number,
  MAX(b.gas_limit) AS block_gas_limit,
  SUM(t.gas_used) AS total_gas_used_by_txs,
  ROUND((SUM(t.gas_used) * 100.0) / NULLIF(MAX(b.gas_limit), 0), 4) AS gas_utilization_pct
FROM
  arbitrum.transactions t
JOIN
  arbitrum.blocks b ON t.block_number = b.number
WHERE
  t.block_time >= TIMESTAMP '2025-05-01'
GROUP BY
  t.block_number
ORDER BY
  t.block_number DESC;
