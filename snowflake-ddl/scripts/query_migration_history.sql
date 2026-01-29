-- ============================================================================
-- Query Migration History
-- Description: Retrieve the last 20 DDL migration deployments
-- ============================================================================

SELECT 
    script_name,
    script_path,
    status,
    TO_CHAR(applied_at, 'YYYY-MM-DD HH24:MI:SS') as applied_at,
    actor
FROM UTIL_DB.UTIL_SCHEMA.DDL_MIGRATION_HISTORY
ORDER BY applied_at DESC
LIMIT 20;
