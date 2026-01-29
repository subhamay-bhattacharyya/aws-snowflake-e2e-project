-- ============================================================================
-- AWS Orders Pipe
-- Description: Snowpipe for automated orders data ingestion from S3 (CSV)
-- ============================================================================

USE ROLE SYSADMIN;
USE WAREHOUSE SB_LOAD_WH;
USE DATABASE SB_BRONZE;
USE SCHEMA RAW_DATA;

-- Create the ORDERS_DATA table
CREATE TABLE IF NOT EXISTS ORDERS_DATA (
    order_id        STRING,
    customer_id     STRING,
    order_date      DATE,
    product         STRING,
    quantity        INTEGER,
    unit_price      NUMBER(10,2),
    region          STRING,
    source_file     STRING,
    load_timestamp  TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
);

-- Create the Snowpipe for ORDERS_DATA
CREATE OR REPLACE PIPE SB_BRONZE.RAW_DATA.ORDERS_PIPE
    AUTO_INGEST = TRUE
    COMMENT = 'Snowpipe for automatic orders CSV data ingestion from S3'
AS
COPY INTO SNW_BRONZE.RAW_DATA.ORDERS_DATA (
    order_id,
    customer_id,
    order_date,
    product,
    quantity,
    unit_price,
    region,
    source_file,
    load_timestamp
)
FROM (
    SELECT
        $1,
        $2,
        $3,
        $4,
        $5,
        $6,
        $7,
        METADATA$FILENAME,
        CURRENT_TIMESTAMP()
    FROM @SNW_BRONZE.UTIL.S3_EXTERNAL_STAGE_CSV
)
FILE_FORMAT = (FORMAT_NAME = 'SNW_BRONZE.UTIL.CSV_FILE_FORMAT')
PATTERN = '.*orders.*\.csv';

-- Show the pipe details and get the notification channel for S3 event setup
SHOW PIPES LIKE 'ORDERS_PIPE' IN SCHEMA SNW_BRONZE.RAW_DATA;

-- Get the notification channel ARN (use this to configure S3 event notifications)
SELECT SYSTEM$PIPE_STATUS('SNW_BRONZE.RAW_DATA.ORDERS_PIPE');
