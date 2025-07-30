WITH 
sequencer_chains AS (
  SELECT chain_name, sequencerInbox_address
  FROM query_5528848
),

eth_prices AS (
  SELECT 
    DATE_TRUNC('month', minute) AS month,
    AVG(price) AS avg_eth_price_usd
  FROM prices.usd
  WHERE blockchain = 'optimism'
        AND symbol = 'ETH' 
        AND minute >= DATE '2023-11-01'
  GROUP BY 1
),

monthly_revenue AS (
  SELECT
    DATE_TRUNC('month', tx.block_time) AS month,
    SUM(CAST(tx.gas_used AS DOUBLE) * CAST(tx.effective_gas_price AS DOUBLE)) AS total_revenue_wei,
    SUM(CAST(tx.gas_used AS DOUBLE) * CAST(tx.effective_gas_price AS DOUBLE)) / 1e18 AS total_revenue_eth
  FROM arbitrum.transactions tx
  JOIN sequencer_chains sc
    ON tx.to = CAST(sc.sequencerInbox_address AS VARBINARY)
  WHERE tx.block_time >= DATE '2023-11-01'
    AND ('{{chain_name}}' = '' OR sc.chain_name = '{{chain_name}}')
  GROUP BY 1
)

SELECT
  mr.month,
  mr.total_revenue_wei,
  mr.total_revenue_eth,
  ep.avg_eth_price_usd,
  mr.total_revenue_eth * ep.avg_eth_price_usd AS total_revenue_usd,
  SUM(mr.total_revenue_eth) OVER (ORDER BY mr.month) AS cumulative_revenue_eth,
  SUM(mr.total_revenue_eth * ep.avg_eth_price_usd) OVER (ORDER BY mr.month) AS cumulative_revenue_usd
FROM monthly_revenue mr
LEFT JOIN eth_prices ep
  ON mr.month = ep.month
ORDER BY mr.month DESC
