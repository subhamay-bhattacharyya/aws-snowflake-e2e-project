-- ============================================================================
-- Analytics Database Grants
-- Description: Grant permissions on analytics database
-- ============================================================================
-- 
-- NOTE: This script runs with SYSADMIN role (with MANAGE GRANTS privilege)
-- SYSADMIN owns the database and can grant privileges to other roles
-- ============================================================================

-- ============================================================================
-- PUBLIC Role Grants
-- Description: Grant read-only access to PUBLIC role for analytics consumption
-- ============================================================================

-- Grant database access to PUBLIC role
-- Allows all users to see and access the lakehouse database
GRANT USAGE ON DATABASE LAKEHOUSE_DB TO ROLE PUBLIC;

-- Grant schema access to PUBLIC role
-- Allows all users to see and access all schemas (Bronze, Silver, Gold, Streamlit)
GRANT USAGE ON ALL SCHEMAS IN DATABASE LAKEHOUSE_DB TO ROLE PUBLIC;

-- Grant read access on existing tables to PUBLIC role
-- Allows all users to query all current tables across all schemas
GRANT SELECT ON ALL TABLES IN DATABASE LAKEHOUSE_DB TO ROLE PUBLIC;

-- Grant read access on future tables to PUBLIC role
-- Automatically grants SELECT on any new tables created in the future
-- Ensures consistent read access without manual grant management
GRANT SELECT ON FUTURE TABLES IN DATABASE LAKEHOUSE_DB TO ROLE PUBLIC; 