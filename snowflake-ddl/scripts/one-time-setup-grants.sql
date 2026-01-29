-- ============================================================================
-- ONE-TIME SETUP: Database Ownership Transfer
-- Description: Run this ONCE as ACCOUNTADMIN to transfer ownership to SYSADMIN
-- ============================================================================
-- 
-- INSTRUCTIONS:
-- 1. Log into Snowflake as ACCOUNTADMIN
-- 2. Run this entire script
-- 3. After this, your GitHub Actions workflow will work with SYSADMIN role
-- ============================================================================

USE ROLE ACCOUNTADMIN;

-- Step 1: Grant MANAGE GRANTS privilege to SYSADMIN
-- This allows SYSADMIN to grant privileges to other roles like PUBLIC
GRANT MANAGE GRANTS ON ACCOUNT TO ROLE SYSADMIN;

-- Step 2: Ensure database exists (if not already created)
CREATE DATABASE IF NOT EXISTS LAKEHOUSE_DB
    COMMENT = 'Lakehouse database following medallion architecture for analytics workloads';

-- Step 3: Transfer database ownership to SYSADMIN
GRANT OWNERSHIP ON DATABASE LAKEHOUSE_DB TO ROLE SYSADMIN COPY CURRENT GRANTS;

-- Step 4: Create schemas if they don't exist
USE DATABASE LAKEHOUSE_DB;

CREATE SCHEMA IF NOT EXISTS BRONZE
    COMMENT = 'Raw data layer - unprocessed data from source systems';

CREATE SCHEMA IF NOT EXISTS SILVER
    COMMENT = 'Cleansed data layer - validated and standardized data';

CREATE SCHEMA IF NOT EXISTS GOLD
    COMMENT = 'Curated data layer - business-ready aggregates and analytics';

CREATE SCHEMA IF NOT EXISTS STREAMLIT
    COMMENT = 'Application layer - objects for Streamlit dashboards and apps';

-- Step 5: Transfer all schema ownership to SYSADMIN
GRANT OWNERSHIP ON ALL SCHEMAS IN DATABASE LAKEHOUSE_DB TO ROLE SYSADMIN COPY CURRENT GRANTS;

-- Step 6: Verify grants
SHOW GRANTS TO ROLE SYSADMIN;

-- Step 7: Verify ownership transfer
SHOW GRANTS ON DATABASE LAKEHOUSE_DB;

-- Confirm SYSADMIN now has proper privileges
SELECT 'Setup complete - SYSADMIN can now manage grants and owns LAKEHOUSE_DB' AS status;
