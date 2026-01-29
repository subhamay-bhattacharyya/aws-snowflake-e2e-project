-- ============================================================================
-- Analytics Database
-- Description: Curated analytics data for reporting
-- ============================================================================

-- Create the lakehouse database for multi-layer data architecture
-- This database follows the medallion architecture (Bronze, Silver, Gold)
-- and serves as the central repository for all analytics workloads
CREATE DATABASE IF NOT EXISTS LAKEHOUSE_DB
    COMMENT = 'Lakehouse database following medallion architecture for analytics workloads';