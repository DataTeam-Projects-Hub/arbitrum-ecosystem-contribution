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
  SUM(tx.gas_used) as gas_used,
  AVG(tx.gas_used) AS avg_gas_used,
  SUM(CAST(tx.gas_used AS DOUBLE) * CAST(tx.effective_gas_price AS DOUBLE)) AS gas_fee_wei,
  SUM((CAST(tx.gas_used AS DOUBLE) * CAST(tx.effective_gas_price AS DOUBLE)) / 1e18) AS gas_fee_eth
FROM arbitrum.transactions AS tx
JOIN sequencer_chains AS sc
  ON tx.to = CAST(sc.sequencerInbox_address AS varbinary)
GROUP BY
  sc.chain_name,
  tx.to