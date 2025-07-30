WITH 
sequencer_chains AS (
  SELECT
    chain_name,
    sequencerInbox_address,
    launch_date
  FROM query_5528848
),

daily_batches AS (
  SELECT
    sc.chain_name,
    tx.to AS to_address,
    DATE(tx.block_date) AS date,
    COUNT(*) AS daily_batches_count
  FROM arbitrum.transactions AS tx
  JOIN sequencer_chains AS sc
    ON tx.to = CAST(sc.sequencerInbox_address AS varbinary)
  WHERE
    ('{{chain_name}}' = '' OR sc.chain_name = '{{chain_name}}')
    AND tx.block_date >= sc.launch_date  
  GROUP BY
    sc.chain_name,
    tx.to,
    DATE(tx.block_date)
)

SELECT
  chain_name,
  to_address,
  date,
  daily_batches_count,
  SUM(daily_batches_count) OVER (
    PARTITION BY chain_name, to_address
    ORDER BY date
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  ) AS cumulative_batches_count
FROM daily_batches
ORDER BY chain_name, to_address, date DESC