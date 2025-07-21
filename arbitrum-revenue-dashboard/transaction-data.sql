WITH transactions AS (
  SELECT
    txs.hash AS tx_hash,
    txs.block_date AS block_date,  
    txs.gas_used,
    txs.gas_used_for_l1,
    txs.priority_fee_per_gas as priority_fee_per_gas,
    txs.gas_price AS gas_price,
    blk.base_fee_per_gas AS base_fee_per_gas,
    txs.effective_gas_price AS effective_gas_price
  FROM
    arbitrum.transactions txs
  JOIN
    arbitrum.blocks blk
    ON txs.block_number = blk.number
  WHERE
     txs.block_date >= TIMESTAMP '2025-05-01'
),

transactions_fees AS (
  SELECT
    block_date,
    
    -- L2 Base Fee in ETH
    ((gas_used - gas_used_for_l1) * effective_gas_price) / 1e18 AS l2_base_fee_eth,

    -- L2 Surplus Fee in ETH
    CASE 
      WHEN priority_fee_per_gas > effective_gas_price  
      THEN ((gas_used - gas_used_for_l1) * priority_fee_per_gas) / 1e18 
      ELSE 0
      END AS l2_surplus_fee_eth
  FROM transactions
),

daily_fee_summary AS (
  SELECT
    block_date,
    SUM(l2_base_fee_eth) AS daily_l2_base_fee_eth,
    SUM(l2_surplus_fee_eth) AS daily_l2_surplus_fee_eth
  FROM transactions_fees
  GROUP BY block_date
),

eth_usd_price AS (
  SELECT
    DATE(minute) AS price_date,
    AVG(price) AS eth_usd_price
  FROM prices.usd
  WHERE symbol = 'ETH'
    AND minute >= TIMESTAMP '2025-05-01'
  GROUP BY DATE(minute)
)

SELECT
  dfs.block_date,
  -- Daily Revenue ETH 
  dfs.daily_l2_base_fee_eth AS l2_base_fee_eth,
  dfs.daily_l2_surplus_fee_eth AS l2_surplus_fee_eth,
  (dfs.daily_l2_base_fee_eth + dfs.daily_l2_surplus_fee_eth) AS revenue_eth,
  
  -- Daily Revenue USD
  (dfs.daily_l2_base_fee_eth * ep.eth_usd_price) AS l2_base_fee_USD,
  (dfs.daily_l2_surplus_fee_eth * ep.eth_usd_price) AS l2_surplus_fee_USD,
  ((dfs.daily_l2_base_fee_eth * ep.eth_usd_price) + (dfs.daily_l2_surplus_fee_eth * ep.eth_usd_price)) AS revenue_USD,
  
  -- Cumulative Revenue ETH
  SUM(dfs.daily_l2_base_fee_eth) OVER (ORDER BY dfs.block_date) AS cumulative_l2_base_fee_eth,
  SUM(dfs.daily_l2_surplus_fee_eth) OVER (ORDER BY dfs.block_date) AS cumulative_l2_surplus_fee_eth,
  SUM(dfs.daily_l2_base_fee_eth) OVER (ORDER BY dfs.block_date) + SUM(dfs.daily_l2_surplus_fee_eth) OVER (ORDER BY dfs.block_date) AS cumulative_revenue_eth,
  
  -- Cumulative Revenue USD
  SUM(dfs.daily_l2_base_fee_eth * ep.eth_usd_price) OVER (ORDER BY dfs.block_date) AS cumulative_l2_base_fee_usd,
  SUM(dfs.daily_l2_surplus_fee_eth * ep.eth_usd_price) OVER (ORDER BY dfs.block_date) AS cumulative_l2_surplus_fee_usd,
  SUM((dfs.daily_l2_base_fee_eth * ep.eth_usd_price) + (dfs.daily_l2_surplus_fee_eth * ep.eth_usd_price)) OVER (ORDER BY dfs.block_date) AS cumulative_revenue_usd

FROM daily_fee_summary dfs
LEFT JOIN eth_usd_price ep
  On dfs.block_date = ep.price_date
ORDER BY
  block_date;
