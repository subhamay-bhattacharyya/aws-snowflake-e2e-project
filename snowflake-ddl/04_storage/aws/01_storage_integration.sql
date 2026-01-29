-- ============================================================================
-- AWS Storage Integration
-- Description: Create storage integration for AWS S3 access
-- ============================================================================
-- 
-- NOTE: No warehouse is required to create storage integration
-- Warehouses are only needed when querying or loading data from stages
-- 
-- CONFIGURATION: Set these variables before running this script
-- Option 1: Set via SQL variables (recommended for CI/CD)
-- Option 2: Replace placeholders manually
-- 
-- AFTER CREATION: You must configure AWS IAM trust policy
-- 1. Run: DESC STORAGE INTEGRATION aws_s3_integration;
-- 2. Copy the STORAGE_AWS_IAM_USER_ARN and STORAGE_AWS_EXTERNAL_ID
-- 3. Update your AWS IAM role trust policy with these values
-- ============================================================================

-- Set configuration variables (replace with actual values or use GitHub Actions variables)
SET aws_role_arn = 'arn:aws:iam::YOUR_AWS_ACCOUNT_ID:role/snowflake-s3-access-role';
SET s3_bucket_name = 'your-bucket-name';

-- Create storage integration for AWS S3
-- This is a metadata operation - no warehouse required
CREATE OR REPLACE STORAGE INTEGRATION aws_s3_integration
    TYPE = EXTERNAL_STAGE
    STORAGE_PROVIDER = 'S3'
    ENABLED = TRUE
    STORAGE_AWS_ROLE_ARN = $aws_role_arn
    STORAGE_ALLOWED_LOCATIONS = (
        CONCAT('s3://', $s3_bucket_name, '/lakehouse/bronze/'),
        CONCAT('s3://', $s3_bucket_name, '/lakehouse/silver/'),
        CONCAT('s3://', $s3_bucket_name, '/lakehouse/gold/')
    )
    STORAGE_BLOCKED_LOCATIONS = ()
    COMMENT = 'Storage integration for AWS S3 lakehouse data access';

-- Grant usage on storage integration to SYSADMIN
GRANT USAGE ON INTEGRATION aws_s3_integration TO ROLE SYSADMIN;

-- Display integration details for AWS IAM configuration
-- Copy the STORAGE_AWS_IAM_USER_ARN and STORAGE_AWS_EXTERNAL_ID values
DESC STORAGE INTEGRATION aws_s3_integration;
