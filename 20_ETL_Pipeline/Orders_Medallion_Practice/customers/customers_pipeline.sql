
-- STEP 1: RAW BRONZE CDC EVENTS

CREATE OR REFRESH STREAMING TABLE
  workspace.sdp_bronze.cdc_customers_bronze_raw

COMMENT 'Raw customer CDC events from JSON'

TBLPROPERTIES (
    'quality' = 'bronze'
)

AS SELECT
    *,
    current_timestamp() AS processing_time,
    _metadata.file_name AS source_file

FROM STREAM read_files(
    '/Volumes/workspace/sdp_bronze/source/customers_cdc',
    format => 'json',
    inferColumnTypes => true
);


-- STEP 2: CLEAN AND VALIDATE CDC EVENTS

CREATE OR REFRESH STREAMING TABLE
  workspace.sdp_bronze.cdc_customers_bronze_clean
(
    CONSTRAINT valid_id
      EXPECT (customer_id IS NOT NULL)
      ON VIOLATION FAIL UPDATE,

    CONSTRAINT valid_operation
      EXPECT (operation IN ('NEW', 'UPDATE', 'DELETE'))
      ON VIOLATION DROP ROW,

    CONSTRAINT valid_name
      EXPECT (
          name IS NOT NULL OR operation = 'DELETE'
      ),

    CONSTRAINT valid_email
      EXPECT (
          email LIKE '%@%' OR operation = 'DELETE'
      )
      ON VIOLATION DROP ROW
)

COMMENT 'Clean customer CDC events with validation'

TBLPROPERTIES (
    'quality' = 'bronze'
)

AS SELECT
    customer_id,
    name,
    email,
    city,
    source_file,
    operation,
    processing_time,
    CAST(timestamp AS BIGINT) AS event_sequence,
    timestamp_seconds(
        CAST(timestamp AS BIGINT)
    ) AS event_time

FROM STREAM workspace.sdp_bronze.cdc_customers_bronze_raw;



-- STEP 3: CREATE THE SCD TYPE 1 TARGET

CREATE OR REFRESH STREAMING TABLE
  workspace.sdp_silver.cdc_customers_silver

COMMENT 'Current active customer state (SCD Type 1)';


CREATE FLOW cdc_customers_type1_flow AS

AUTO CDC INTO
    workspace.sdp_silver.cdc_customers_silver

FROM STREAM
    workspace.sdp_bronze.cdc_customers_bronze_clean

KEYS (customer_id)

APPLY AS DELETE WHEN
    operation = 'DELETE'

SEQUENCE BY event_sequence

COLUMNS * EXCEPT (
    operation,
    event_sequence,
    processing_time,
    source_file
)

STORED AS SCD TYPE 1;



