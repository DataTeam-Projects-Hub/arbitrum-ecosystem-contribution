WITH 
sequencer_chains AS (
  SELECT chain_name, sequencerInbox_address
  FROM query_5528848
),
flattened_chains AS (
  SELECT
    sc.chain_name,
    t.single_address
  FROM sequencer_chains AS sc
  CROSS JOIN UNNEST(sc.sequencerInbox_address) AS t(single_address)
),
selected_chains_label AS (
  SELECT 
    CASE 
      WHEN '{{chain_name}}' = '' THEN 'All Chains'
      ELSE '{{chain_name}}'
    END AS display_label
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
  JOIN flattened_chains fc
    ON tx.to = fc.single_address
  WHERE tx.block_time >= DATE '2023-11-01'
    AND (
      '{{chain_name}}' = '' 
      OR fc.chain_name IN (
        SELECT TRIM(value) 
        FROM UNNEST(SPLIT('{{chain_name}}', ',')) AS t(value)
      )
    )
  GROUP BY DATE_TRUNC('month', tx.block_time)
)
SELECT
  scl.display_label AS selected_chains,
  mr.month,
  mr.total_revenue_wei,
  mr.total_revenue_eth,
  ep.avg_eth_price_usd,
  mr.total_revenue_eth * ep.avg_eth_price_usd AS monthly_revenue_usd,
  SUM(mr.total_revenue_eth) OVER (ORDER BY mr.month) AS cumulative_revenue_eth,
  SUM(mr.total_revenue_eth * ep.avg_eth_price_usd) OVER (ORDER BY mr.month) AS cumulative_revenue_usd
FROM monthly_revenue mr
LEFT JOIN eth_prices ep
  ON mr.month = ep.month
CROSS JOIN selected_chains_label scl
ORDER BY mr.month DESC