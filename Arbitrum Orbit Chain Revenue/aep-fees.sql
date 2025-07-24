SELECT
  t.block_date,
  
  CAST(SUM(COALESCE(t.gas_used, 0) - COALESCE(t.l1_gas_used, 0)) AS DECIMAL(38,0)) AS total_l2_gas_used,

  CAST(SUM(
    (COALESCE(t.gas_used, 0) - COALESCE(t.l1_gas_used, 0)) * b.base_fee_per_gas
  ) AS DECIMAL(38,0)) AS l2_base_fee_wei,

  CAST(SUM(
    COALESCE(t.priority_fee_per_gas, 0) * (COALESCE(t.gas_used, 0) - COALESCE(t.l1_gas_used, 0))
  ) AS DECIMAL(38,0)) AS l2_surplus_fee_wei,

  CAST(SUM(COALESCE(t.l1_fee, 0)) AS DECIMAL(38,0)) AS settlement_cost_wei,

  -- Convert wei values to ETH with fixed decimals:
  CAST(SUM(
    (COALESCE(t.gas_used, 0) - COALESCE(t.l1_gas_used, 0)) * b.base_fee_per_gas
  ) AS DECIMAL(38,0)) / 1e18 AS l2_base_fee_eth,

  CAST(SUM(
    COALESCE(t.priority_fee_per_gas, 0) * (COALESCE(t.gas_used, 0) - COALESCE(t.l1_gas_used, 0))
  ) AS DECIMAL(38,0)) / 1e18 AS l2_surplus_fee_eth,

  CAST(SUM(COALESCE(t.l1_fee, 0)) AS DECIMAL(38,0)) / 1e18 AS settlement_cost_eth,

  -- aep_fee example (also cast)
  CAST(
    CASE 
      WHEN 
        SUM(
          (COALESCE(t.gas_used, 0) - COALESCE(t.l1_gas_used, 0)) * b.base_fee_per_gas
        ) + SUM(
          COALESCE(t.priority_fee_per_gas, 0) * (COALESCE(t.gas_used, 0) - COALESCE(t.l1_gas_used, 0))
        ) > SUM(COALESCE(t.l1_fee, 0))
      THEN (
        (
          SUM(
            (COALESCE(t.gas_used, 0) - COALESCE(t.l1_gas_used, 0)) * b.base_fee_per_gas
          ) + SUM(
            COALESCE(t.priority_fee_per_gas, 0) * (COALESCE(t.gas_used, 0) - COALESCE(t.l1_gas_used, 0))
          ) - SUM(COALESCE(t.l1_fee, 0))
        ) * 0.1
      )
      ELSE 0
    END AS DECIMAL(38,0)
  ) AS aep_fee_wei,

  CAST(
    CASE 
      WHEN 
        SUM(
          (COALESCE(t.gas_used, 0) - COALESCE(t.l1_gas_used, 0)) * b.base_fee_per_gas
        ) + SUM(
          COALESCE(t.priority_fee_per_gas, 0) * (COALESCE(t.gas_used, 0) - COALESCE(t.l1_gas_used, 0))
        ) > SUM(COALESCE(t.l1_fee, 0))
      THEN (
        (
          SUM(
            (COALESCE(t.gas_used, 0) - COALESCE(t.l1_gas_used, 0)) * b.base_fee_per_gas
          ) + SUM(
            COALESCE(t.priority_fee_per_gas, 0) * (COALESCE(t.gas_used, 0) - COALESCE(t.l1_gas_used, 0))
          ) - SUM(COALESCE(t.l1_fee, 0))
        ) * 0.1
      )
      ELSE 0
    END AS DECIMAL(38,18)
  ) / 1e18 AS aep_fee_eth

FROM base.transactions AS t
JOIN base.blocks AS b ON t.block_number = b.number
WHERE t.to = FROM_HEX('6216dd1ee27c5acec7427052d3ecdc98e2bc2221')
GROUP BY t.block_date
ORDER BY t.block_date;
