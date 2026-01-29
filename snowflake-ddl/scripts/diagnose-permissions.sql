-- ============================================================================
-- DIAGNOSTIC SCRIPT: Check Database Ownership and Permissions
-- Description: Run this to diagnose permission issues
-- ============================================================================

-- Check current role
SELECT CURRENT_ROLE() AS current_role;

-- Check what roles the current user has
SHOW GRANTS TO USER CURRENT_USER();

-- Check who owns the database
SHOW GRANTS ON DATABASE LAKEHOUSE_DB;

-- Check SYSADMIN privileges
SHOW GRANTS TO ROLE SYSADMIN;

-- Check if SYSADMIN has MANAGE GRANTS
-- Look for "MANAGE GRANTS" in the output above

-- Check database ownership specifically
SELECT 
    'LAKEHOUSE_DB' AS database_name,
    GRANTEE_NAME AS owner_role,
    PRIVILEGE AS privilege_type
FROM SNOWFLAKE.ACCOUNT_USAGE.GRANTS_TO_ROLES
WHERE GRANTED_ON = 'DATABASE'
  AND NAME = 'LAKEHOUSE_DB'
  AND PRIVILEGE = 'OWNERSHIP'
  AND DELETED_ON IS NULL
ORDER BY CREATED_ON DESC
LIMIT 10;
