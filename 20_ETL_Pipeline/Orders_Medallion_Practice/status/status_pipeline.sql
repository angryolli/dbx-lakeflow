
-- A. STATUS BRONZE

CREATE OR REFRESH STREAMING TABLE
  workspace.sdp_bronze.status_bronze

COMMENT 'Raw order status events from JSON'

TBLPROPERTIES (
  'quality' = 'bronze',
  'pipelines.reset.allowed' = 'false'
)

AS SELECT
    *,
    current_timestamp() AS processing_time,
    _metadata.file_name AS source_file

FROM STREAM read_files(
    '/Volumes/workspace/sdp_bronze/source/status',
    format => 'json',
    inferColumnTypes => true
);



-- B. STATUS SILVER

CREATE OR REFRESH STREAMING TABLE
  workspace.sdp_silver.status_silver
(
  CONSTRAINT valid_timestamp
    EXPECT (
      order_status_timestamp > TIMESTAMP '2021-12-26'
    )
    ON VIOLATION DROP ROW,

  CONSTRAINT valid_order_status
    EXPECT (
      order_status IN (
        'placed',
        'preparing',
        'on the way',
        'delivered',
        'canceled',
        'return requested',
        'return picked up',
        'return processed',
        'return canceled',
        'reported shipping error'
      )
    )
)

COMMENT 'Clean order status history'

TBLPROPERTIES (
  'quality' = 'silver'
)

AS SELECT
    order_id,
    order_status,
    timestamp_seconds(
      CAST(status_timestamp AS BIGINT)
    ) AS order_status_timestamp

FROM STREAM workspace.sdp_bronze.status_bronze;


-- C. GOLD: JOIN ORDERS AND STATUS HISTORY

CREATE OR REFRESH MATERIALIZED VIEW
  workspace.sdp_gold.full_order_info_gold

COMMENT 'Complete order and status history'

TBLPROPERTIES (
  'quality' = 'gold'
)

AS SELECT
    orders.order_id,
    orders.customer_id,
    orders.order_timestamp,

    status.order_status,
    status.order_status_timestamp

FROM workspace.sdp_silver.status_silver AS status

INNER JOIN workspace.sdp_silver.orders_silver AS orders
    ON orders.order_id = status.order_id;



-- D. GOLD: CANCELLED ORDERS

CREATE OR REFRESH MATERIALIZED VIEW
  workspace.sdp_gold.cancelled_orders_gold

COMMENT 'Cancelled orders and cancellation duration'

TBLPROPERTIES (
  'quality' = 'gold'
)

AS SELECT
    order_id,
    order_timestamp,
    order_status,
    order_status_timestamp,

    datediff(
      DATE(order_status_timestamp),
      DATE(order_timestamp)
    ) AS days_to_cancel

FROM workspace.sdp_gold.full_order_info_gold

WHERE order_status = 'canceled';


-- E. GOLD: DELIVERED ORDERS

CREATE OR REFRESH MATERIALIZED VIEW
  workspace.sdp_gold.delivered_orders_gold

COMMENT 'Delivered orders and delivery duration'

TBLPROPERTIES (
  'quality' = 'gold'
)

AS SELECT
    order_id,
    order_timestamp,
    order_status,
    order_status_timestamp,

    datediff(
      DATE(order_status_timestamp),
      DATE(order_timestamp)
    ) AS days_to_delivery

FROM workspace.sdp_gold.full_order_info_gold

WHERE order_status = 'delivered';
