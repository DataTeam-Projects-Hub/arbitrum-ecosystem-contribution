WITH 
sequencer_chains AS (
  SELECT
    chain_name,
    sequencerInbox_address
  FROM query_5528848
),

eth_price AS (
  SELECT
    AVG(price) AS avg_eth_price_usd
  FROM prices.usd
  WHERE 
    blockchain = 'optimism'
    AND symbol = 'ETH'
    AND minute >= DATE '2023-11-01'  
)

SELECT
  sc.chain_name,
  tx.to AS to_address,
  SUM(CAST(tx.gas_used AS DOUBLE) * CAST(tx.effective_gas_price AS DOUBLE)) AS revenue_wei,
  SUM((CAST(tx.gas_used AS DOUBLE) * CAST(tx.effective_gas_price AS DOUBLE)) / 1e18) AS revenue_eth,
  ep.avg_eth_price_usd,
  SUM((CAST(tx.gas_used AS DOUBLE) * CAST(tx.effective_gas_price AS DOUBLE)) / 1e18) * ep.avg_eth_price_usd AS revenue_usd
FROM arbitrum.transactions AS tx
JOIN sequencer_chains AS sc
  ON tx.to = CAST(sc.sequencerInbox_address AS varbinary)
CROSS JOIN eth_price ep
GROUP BY
  sc.chain_name,
  tx.to,
  ep.avg_eth_price_usd
