WITH 
timeboost_txs AS (
  SELECT
    CAST(block_time AS date) AS day,
    contract_address,
    block_date,
    bytearray_to_uint256(bytearray_substring(data, 65, 32)) / 1e18 AS first_price_amount_eth
  FROM
    arbitrum.logs
  WHERE
    block_time >= TIMESTAMP '2025-05-01'
    AND topic0 = 0x7f5bdabbd27a8fc572781b177055488d7c6729a2bade4f57da9d200f31c15d47 -- AuctionResolved
    AND contract_address IN (
        0x5fcb496a31b7ae91e7c9078ec662bd7a55cd3079, -- TimeBoost auction contracts
        0xa5aBADAF73DFcf5261C7f55420418736707Dc0db
    )
),

eth_prices AS (
  SELECT
    DATE(minute) AS day,
    AVG(price) AS eth_price_usd
  FROM
    prices.usd
  WHERE
    symbol = 'ETH'
    AND DATE(minute) >= DATE('2025-05-01')
  GROUP BY
    DATE(minute)
),

revenue_with_prices AS (
  SELECT
    d.day,
    SUM(d.first_price_amount_eth) AS total_timeboost_revenue_eth,
    AVG(p.eth_price_usd) AS avg_eth_price_usd,
    SUM(d.first_price_amount_eth) * AVG(p.eth_price_usd) AS total_timeboost_revenue_usd
  FROM
    timeboost_txs d
  LEFT JOIN
    eth_prices p ON d.day = p.day
  GROUP BY
    d.day
),

tx_counts AS (
  SELECT
    CAST(block_time AS date) AS day,
    COUNT(*) AS total_tx_count
  FROM
    arbitrum.transactions
  WHERE
    block_time >= TIMESTAMP '2025-05-01'
  GROUP BY
    CAST(block_time AS date)
),

boosted_tx_counts AS (
  SELECT
    day,
    COUNT(*) AS boosted_tx_count
  FROM
    timeboost_txs
  GROUP BY
    day
),
boost_usage AS (
  SELECT
    t.day,
    t.total_tx_count,
    COALESCE(b.boosted_tx_count, 0) AS boosted_tx_count,
    (CAST(COALESCE(b.boosted_tx_count, 0) AS DOUBLE) / NULLIF(t.total_tx_count, 0)) * 100 AS percent_boosted
    -- (COALESCE(b.boosted_tx_count, 0)::FLOAT / NULLIF(t.total_tx_count, 0)) * 100 AS percent_boosted
  FROM
    tx_counts t
  LEFT JOIN
    boosted_tx_counts b ON t.day = b.day
)
SELECT
  r.day,
  r.total_timeboost_revenue_eth,
  SUM(r.total_timeboost_revenue_eth) OVER (ORDER BY r.day) AS cumulative_revenue_eth,
  r.avg_eth_price_usd,
  r.total_timeboost_revenue_usd,
  SUM(r.total_timeboost_revenue_usd) OVER (ORDER BY r.day) AS cumulative_revenue_usd,
  b.boosted_tx_count,
  u.total_tx_count,
  u.percent_boosted,
  r.total_timeboost_revenue_eth / NULLIF(b.boosted_tx_count, 0) AS avg_revenue_per_boosted_tx_eth,
  r.total_timeboost_revenue_usd / NULLIF(b.boosted_tx_count, 0) AS avg_revenue_per_boosted_tx_usd
FROM
  revenue_with_prices r
LEFT JOIN
  boost_usage u ON r.day = u.day
LEFT JOIN
  boosted_tx_counts b ON r.day = b.day
ORDER BY
  r.day;
