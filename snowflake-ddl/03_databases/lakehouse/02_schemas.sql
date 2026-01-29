-- ============================================================================
-- Analytics Database Schemas
-- Description: Create schemas within analytics database
-- ============================================================================

-- Ensure the lakehouse database exists
CREATE DATABASE IF NOT EXISTS LAKEHOUSE_DB;

-- Set context to lakehouse database
USE LAKEHOUSE_DB;

-- Bronze layer: Raw data ingestion zone
-- Contains unprocessed data as-is from source systems
CREATE SCHEMA IF NOT EXISTS BRONZE
    COMMENT = 'Raw data layer - unprocessed data from source systems';

-- Silver layer: Cleaned and validated data
-- Contains cleansed, validated, and deduplicated data
CREATE SCHEMA IF NOT EXISTS SILVER
    COMMENT = 'Cleansed data layer - validated and standardized data';

-- Gold layer: Business-level aggregates and analytics
-- Contains aggregated, business-ready data for reporting and analytics
CREATE SCHEMA IF NOT EXISTS GOLD
    COMMENT = 'Curated data layer - business-ready aggregates and analytics';

-- Streamlit layer: Application-specific objects
-- Contains views, tables, and functions for Streamlit applications
CREATE SCHEMA IF NOT EXISTS STREAMLIT
    COMMENT = 'Application layer - objects for Streamlit dashboards and apps';
