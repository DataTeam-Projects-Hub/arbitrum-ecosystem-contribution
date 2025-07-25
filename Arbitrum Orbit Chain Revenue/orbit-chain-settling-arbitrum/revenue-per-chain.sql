WITH 
sequencer_chains AS (
  SELECT
    chain_name,
    sequencerInbox_address
  FROM query_5528848
)

SELECT
  sc.chain_name,
  tx.to AS to_address,
  SUM(CAST(tx.gas_used AS DOUBLE) * CAST(tx.effective_gas_price AS DOUBLE)) AS revenue_wei,
  SUM((CAST(tx.gas_used AS DOUBLE) * CAST(tx.effective_gas_price AS DOUBLE)) / 1e18) AS revenue_eth
FROM arbitrum.transactions AS tx
JOIN sequencer_chains AS sc
  ON tx.to = CAST(sc.sequencerInbox_address AS varbinary)
WHERE
  -- If parameter is empty, select all chains; else filter by selected chain
  ('{{chain_name}}' = '' OR sc.chain_name = '{{chain_name}}')
GROUP BY
  sc.chain_name,
  tx.to