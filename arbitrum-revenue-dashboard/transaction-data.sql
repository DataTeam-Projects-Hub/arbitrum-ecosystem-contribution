WITH transactions AS (
  SELECT
    txs.hash AS tx_hash,
    DATE(txs.block_time) AS block_date,  -- Extract date for grouping
    txs.gas_used,
    txs.gas_used_for_l1,
    txs.gas_price AS gas_price,
    blk.base_fee_per_gas AS base_fee_per_gas,
    txs.effective_gas_price AS effective_gas_price
  FROM
    arbitrum.transactions txs
  JOIN
    arbitrum.blocks blk
    ON txs.block_number = blk.number
  WHERE
     txs.block_time >= TIMESTAMP '2025-04-16'
),

transactions_fees AS (
  SELECT
    block_date,
    
    -- L2 Base Fee in ETH
    ((gas_used - gas_used_for_l1) * effective_gas_price) / 1e18 AS l2_base_fee_eth,

    -- L2 Surplus Fee in ETH
    CASE 
      WHEN gas_price > effective_gas_price  
      THEN ((gas_used - gas_used_for_l1) * (gas_price - effective_gas_price)) / 1e18 
      ELSE 0
      END AS l2_surplus_fee_eth,

    -- L1 Surplus Fee in ETH
    CASE
      WHEN gas_price > effective_gas_price
      THEN (gas_used_for_l1 * (gas_price - effective_gas_price)) / 1e18 
      ELSE 0
      END AS l1_surplus_fee_eth

  FROM transactions
),

daily_fee_summary AS (
  SELECT
    block_date,
    SUM(l2_base_fee_eth) AS daily_l2_base_fee_eth,
    SUM(l2_surplus_fee_eth) AS daily_l2_surplus_fee_eth,
    SUM(l1_surplus_fee_eth) AS daily_l1_surplus_fee_eth
  FROM transactions_fees
  GROUP BY block_date
)

SELECT
  block_date,
  daily_l2_base_fee_eth,
  daily_l2_surplus_fee_eth,
  daily_l1_surplus_fee_eth,
  
  -- Cumulative totals
  SUM(daily_l2_base_fee_eth) OVER (ORDER BY block_date) AS cumulative_l2_base_fee_eth,
  SUM(daily_l2_surplus_fee_eth) OVER (ORDER BY block_date) AS cumulative_l2_surplus_fee_eth,
  SUM(daily_l1_surplus_fee_eth) OVER (ORDER BY block_date) AS cumulative_l1_surplus_fee_eth
FROM
  daily_fee_summary
ORDER BY
  block_date;
