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
  COUNT(*) AS total_batches
FROM arbitrum.transactions AS tx
JOIN sequencer_chains AS sc
  ON tx.to = CAST(sc.sequencerInbox_address AS varbinary)
GROUP BY
  sc.chain_name,
  tx.to
