WITH 
sequencer_chains AS (
  SELECT
    chain_name,
    sequencerInbox_address
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
filtered_tx AS (
  SELECT
    DATE_TRUNC('day', tx.block_time) AS day,
    tx.gas_used,
    tx.effective_gas_price
  FROM arbitrum.transactions AS tx
  JOIN flattened_chains AS fc
    ON tx.to = fc.single_address
  WHERE
    tx.block_time >= CURRENT_DATE - INTERVAL '30' DAY
    AND (
      '{{chain_name}}' = '' 
      OR fc.chain_name IN (
        SELECT TRIM(value) 
        FROM UNNEST(SPLIT('{{chain_name}}', ',')) AS t(value)
      )
    )
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
    blockchain = 'optimism'
    AND symbol = 'ETH' 
    AND minute >= CURRENT_DATE - INTERVAL '30' DAY
  GROUP BY
    1
)
SELECT
  scl.display_label AS selected_chains,
  r.day,
  r.total_revenue_eth,
  p.eth_price_usd,
  r.total_revenue_eth * p.eth_price_usd AS total_revenue_usd
FROM eth_revenue_per_day AS r
LEFT JOIN eth_price_per_day AS p
  ON r.day = p.day
CROSS JOIN selected_chains_label scl
ORDER BY
  r.day DESC