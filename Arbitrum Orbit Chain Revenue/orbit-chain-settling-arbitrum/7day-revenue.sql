WITH 
sequencer_chains AS (
  SELECT
    chain_name,
    sequencerInbox_address
  FROM query_5528848
), 

filtered_tx AS (
  SELECT
    DATE_TRUNC('day', tx.block_time) AS day,
    tx.gas_used,
    tx.effective_gas_price
  FROM arbitrum.transactions AS tx
  JOIN sequencer_chains AS sc
    ON tx.to = TRY_CAST(sc.sequencerInbox_address AS VARBINARY)
  WHERE
    tx.block_time >= CURRENT_DATE - INTERVAL '7' DAY
    AND ('{{chain_name}}' = '' OR sc.chain_name = '{{chain_name}}')
), 

eth_revenue_per_day AS (
  SELECT
    day,
    SUM((TRY_CAST(gas_used AS DOUBLE) * TRY_CAST(effective_gas_price AS DOUBLE)) / 1e18) AS total_revenue_eth
  FROM filtered_tx
  GROUP BY
    day
), 

eth_price_per_day AS (
  SELECT
    DATE_TRUNC('day', minute) AS day,
    AVG(price) AS eth_price_usd
  FROM prices.usd
  WHERE 
    symbol = 'ETH' AND minute >= CURRENT_DATE - INTERVAL '7' DAY
  GROUP BY
    1
)

SELECT
  r.day,
  r.total_revenue_eth,
  p.eth_price_usd,
  r.total_revenue_eth * p.eth_price_usd AS total_revenue_usd
FROM eth_revenue_per_day AS r
LEFT JOIN eth_price_per_day AS p
  ON r.day = p.day
ORDER BY
  r.day DESC