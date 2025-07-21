-- https://dune.com/queries/5512513
SELECT
  block_date,
  block_time,
  block_number,
  hash AS tx_hash,
  "from" AS sender,
  "to" AS recipient,
  gas_used,
  priority_fee_per_gas,
  (TRY_CAST(gas_used AS DECIMAL) * TRY_CAST(priority_fee_per_gas AS DECIMAL)) AS extra_paid_degen
FROM
  degen.transactions
WHERE
  success = TRUE
ORDER BY
  block_date DESC, block_time DESC
LIMIT 5000  -- or any number you prefer for easier checking
