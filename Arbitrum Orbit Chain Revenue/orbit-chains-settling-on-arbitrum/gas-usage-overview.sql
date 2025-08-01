WITH 
sequencer_chains AS (
  SELECT
    chain_name,
    sequencerInbox_address,
    launch_date
  FROM query_5528848
),
flattened_chains AS (
  SELECT
    sc.chain_name,
    t.single_address,
    sc.launch_date
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
daily_data AS (
  SELECT
    DATE(tx.block_date) AS date,
    SUM(tx.gas_used) AS gas_used,
    AVG(tx.gas_used) AS avg_gas_used,
    SUM((CAST(tx.gas_used AS DOUBLE) * CAST(tx.effective_gas_price AS DOUBLE)) / 1e18) AS daily_gas_fee_eth,
    COUNT(*) AS daily_transaction_count,
    AVG((CAST(tx.gas_used AS DOUBLE) * CAST(tx.effective_gas_price AS DOUBLE)) / 1e18) AS avg_gas_fee_per_tx_eth
  FROM arbitrum.transactions AS tx
  JOIN flattened_chains AS fc
    ON tx.to = fc.single_address
  WHERE
    (
      '{{chain_name}}' = '' 
      OR fc.chain_name IN (
        SELECT TRIM(value) 
        FROM UNNEST(SPLIT('{{chain_name}}', ',')) AS t(value)
      )
    )
  GROUP BY
    DATE(tx.block_date)  -- Removed fc.chain_name from GROUP BY to aggregate across chains
)
SELECT
  scl.display_label AS selected_chains,
  dd.date, 
  dd.gas_used,
  dd.avg_gas_used,
  dd.daily_gas_fee_eth,
  dd.avg_gas_fee_per_tx_eth,
  SUM(dd.gas_used) OVER (
    ORDER BY dd.date 
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  ) AS cumulative_gas_used  
 
FROM daily_data dd
CROSS JOIN selected_chains_label scl
ORDER BY dd.date DESC