WITH 
sequencer_chains AS (
  SELECT
    chain_name,
    sequencerInbox_address
  FROM query_5528848
)

SELECT
  SUM(CAST(tx.gas_used AS DOUBLE) * CAST(tx.effective_gas_price AS DOUBLE)) AS total_revenue_wei,
  SUM((CAST(tx.gas_used AS DOUBLE) * CAST(tx.effective_gas_price AS DOUBLE)) / 1e18) AS total_revenue_eth
FROM arbitrum.transactions AS tx
JOIN sequencer_chains AS sc
  ON tx.to = CAST(sc.sequencerInbox_address AS varbinary)
WHERE
  ('{{chain_name}}' = '' OR sc.chain_name = '{{chain_name}}')
