-- ============================================================================
-- AWS External Stages
-- Description: Create external stages for S3 data access
-- ============================================================================
-- 
-- NOTE: No warehouse is required to create external stages
-- Warehouses are only needed when:
--   - Listing files: LIST @stage_name
--   - Loading data: COPY INTO table FROM @stage_name
--   - Querying data: SELECT * FROM @stage_name
-- 
-- PREREQUISITE: Storage integration must be created first
-- See: 01_storage_integration.sql
-- ============================================================================

-- Set context to lakehouse database
USE DATABASE LAKEHOUSE_DB;

-- ============================================================================
-- Bronze Layer External Stage
-- Description: Raw data ingestion from S3
-- ============================================================================

CREATE OR REPLACE STAGE BRONZE.s3_bronze_stage
    STORAGE_INTEGRATION = aws_s3_integration
    URL = 's3://your-bucket-name/lakehouse/bronze/'
    FILE_FORMAT = (
        TYPE = 'JSON'
        COMPRESSION = 'AUTO'
        STRIP_OUTER_ARRAY = TRUE
    )
    COMMENT = 'External stage for raw data ingestion from S3 bronze layer';

-- Grant usage on bronze stage
GRANT USAGE ON STAGE BRONZE.s3_bronze_stage TO ROLE SYSADMIN;
GRANT READ ON STAGE BRONZE.s3_bronze_stage TO ROLE PUBLIC;

-- ============================================================================
-- Silver Layer External Stage
-- Description: Cleansed data from S3
-- ============================================================================

CREATE OR REPLACE STAGE SILVER.s3_silver_stage
    STORAGE_INTEGRATION = aws_s3_integration
    URL = 's3://your-bucket-name/lakehouse/silver/'
    FILE_FORMAT = (
        TYPE = 'PARQUET'
        COMPRESSION = 'SNAPPY'
    )
    COMMENT = 'External stage for cleansed data from S3 silver layer';

-- Grant usage on silver stage
GRANT USAGE ON STAGE SILVER.s3_silver_stage TO ROLE SYSADMIN;
GRANT READ ON STAGE SILVER.s3_silver_stage TO ROLE PUBLIC;

-- ============================================================================
-- Gold Layer External Stage
-- Description: Curated analytics data from S3
-- ============================================================================

CREATE OR REPLACE STAGE GOLD.s3_gold_stage
    STORAGE_INTEGRATION = aws_s3_integration
    URL = 's3://your-bucket-name/lakehouse/gold/'
    FILE_FORMAT = (
        TYPE = 'PARQUET'
        COMPRESSION = 'SNAPPY'
    )
    COMMENT = 'External stage for curated analytics data from S3 gold layer';

-- Grant usage on gold stage
GRANT USAGE ON STAGE GOLD.s3_gold_stage TO ROLE SYSADMIN;
GRANT READ ON STAGE GOLD.s3_gold_stage TO ROLE PUBLIC;

-- ============================================================================
-- CSV File Format (Optional)
-- Description: For CSV data ingestion
-- ============================================================================

CREATE OR REPLACE FILE FORMAT BRONZE.csv_format
    TYPE = 'CSV'
    FIELD_DELIMITER = ','
    SKIP_HEADER = 1
    NULL_IF = ('NULL', 'null', '')
    EMPTY_FIELD_AS_NULL = TRUE
    COMPRESSION = 'AUTO'
    COMMENT = 'CSV file format for data ingestion';

-- ============================================================================
-- Verify Stages
-- Description: List all stages and test connectivity
-- ============================================================================

-- List all stages in the database (no warehouse required)
SHOW STAGES IN DATABASE LAKEHOUSE_DB;

-- ============================================================================
-- Testing Stage Connectivity (REQUIRES WAREHOUSE)
-- Description: Uncomment and run these commands to test stage access
-- NOTE: You must have a warehouse running to execute these commands
-- ============================================================================

-- Set a warehouse for testing (uncomment to use)
-- USE WAREHOUSE COMPUTE_WH;

-- Test stage connectivity by listing files (requires warehouse)
-- LIST @BRONZE.s3_bronze_stage;
-- LIST @SILVER.s3_silver_stage;
-- LIST @GOLD.s3_gold_stage;

-- Query data directly from stage (requires warehouse)
-- SELECT $1, $2, $3 FROM @BRONZE.s3_bronze_stage (FILE_FORMAT => 'BRONZE.csv_format') LIMIT 10;
