WITH 
sequencer_chains AS (
  SELECT
    chain_name,
    sequencerInbox_address,
    launch_date
  FROM query_5528848
),

daily_data AS (
  SELECT
    sc.chain_name,
    DATE(tx.block_date) AS date,
    SUM(tx.gas_used) AS gas_used,
    AVG(tx.gas_used) AS avg_gas_used,
    SUM((CAST(tx.gas_used AS DOUBLE) * CAST(tx.effective_gas_price AS DOUBLE)) / 1e18) AS daily_gas_fee_eth,
    COUNT(*) AS daily_transaction_count,
    AVG((CAST(tx.gas_used AS DOUBLE) * CAST(tx.effective_gas_price AS DOUBLE)) / 1e18) AS avg_gas_fee_per_tx_eth
  FROM arbitrum.transactions AS tx
  JOIN sequencer_chains AS sc
    ON tx.to = CAST(sc.sequencerInbox_address AS varbinary)
  WHERE
    ('{{chain_name}}' = '' OR sc.chain_name = '{{chain_name}}')
    AND tx.block_date >= sc.launch_date 
  GROUP BY
    sc.chain_name,
    DATE(tx.block_date)
)

SELECT
  chain_name,
  date, 
  gas_used,
  avg_gas_used,
  SUM(gas_used) OVER (
    PARTITION BY chain_name 
    ORDER BY date 
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  ) AS cumulative_gas_used,    
  daily_transaction_count,
  SUM(daily_transaction_count) OVER (
    PARTITION BY chain_name 
    ORDER BY date 
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  ) AS cumulative_transaction_count  
FROM daily_data
ORDER BY chain_name, date DESC