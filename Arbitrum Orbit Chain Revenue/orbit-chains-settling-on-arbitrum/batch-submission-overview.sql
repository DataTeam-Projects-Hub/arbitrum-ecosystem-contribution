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
daily_batches AS (
  SELECT
    DATE(tx.block_date) AS date,
    COUNT(*) AS daily_batches_count
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
    DATE(tx.block_date)  -- Aggregates across all selected chains
)
SELECT
  scl.display_label AS selected_chains,
  db.date,
  db.daily_batches_count,
  SUM(db.daily_batches_count) OVER (
    ORDER BY db.date
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  ) AS cumulative_batches_count
FROM daily_batches db
CROSS JOIN selected_chains_label scl
ORDER BY db.date DESC