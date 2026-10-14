
-- BRONZE: Incremental ingestion of raw JSON orders

CREATE OR REFRESH STREAMING TABLE
  workspace.sdp_bronze.orders_bronze
AS
SELECT
    *,
    current_timestamp() AS processing_time,
    _metadata.file_name AS source_file
FROM STREAM read_files(
    '${source}/orders',
    format => 'json',
    inferColumnTypes => true
);

-- SILVER: Select and clean the order data
CREATE OR REFRESH STREAMING TABLE
  sdp_silver.orders_silver
(
  -- WARN: Keep invalid rows, but record the violation
  CONSTRAINT valid_notifications
    EXPECT (notifications IN ('Y', 'X')),

  -- DROP: Exclude rows with invalid dates
  CONSTRAINT valid_date
    EXPECT (order_timestamp > '2021-12-26')
    ON VIOLATION DROP ROW,

  -- FAIL: Stop the update if customer_id is NULL
  CONSTRAINT valid_id
    EXPECT (customer_id IS NOT NULL)
    ON VIOLATION FAIL UPDATE
)
AS
SELECT
    order_id,
    timestamp_seconds(CAST(order_timestamp AS BIGINT))
      AS order_timestamp,
    customer_id,
    notifications
FROM STREAM sdp_bronze.orders_bronze;

-- GOLD: Aggregate orders by date

CREATE OR REFRESH MATERIALIZED VIEW
  sdp_gold.orders_by_date
AS
SELECT
    DATE(order_timestamp) AS order_date,
    COUNT(*) AS total_daily_orders
FROM sdp_silver.orders_silver
GROUP BY DATE(order_timestamp);