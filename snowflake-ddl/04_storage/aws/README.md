# AWS Storage Integration Setup

This directory contains DDL scripts for setting up AWS S3 storage integration with Snowflake.

## Prerequisites

1. **AWS S3 Bucket**: Create an S3 bucket with the following structure:
   ```
   your-bucket-name/
   └── lakehouse/
       ├── bronze/    # Raw data
       ├── silver/    # Cleansed data
       └── gold/      # Curated data
   ```

2. **AWS IAM Role**: Create an IAM role with S3 access permissions

3. **Snowflake Warehouse** (Optional for creation, required for usage):
   - NOT required to create storage integrations and stages
   - REQUIRED to list files, load data, or query from stages

## Setup Steps

### Step 1: Update Configuration

Edit `01_storage_integration.sql` and replace:
- `YOUR_AWS_ACCOUNT_ID` - Your AWS account ID
- `your-bucket-name` - Your S3 bucket name
- `snowflake-s3-access-role` - Your IAM role name

Edit `02_external_stages.sql` and replace:
- `your-bucket-name` - Your S3 bucket name

### Step 2: Create Storage Integration

Run `01_storage_integration.sql` in Snowflake as ACCOUNTADMIN:

```sql
USE ROLE ACCOUNTADMIN;
-- Execute the script
```

### Step 3: Configure AWS IAM Trust Policy

After creating the storage integration, run:

```sql
DESC STORAGE INTEGRATION aws_s3_integration;
```

Copy the following values:
- `STORAGE_AWS_IAM_USER_ARN`
- `STORAGE_AWS_EXTERNAL_ID`

Update your AWS IAM role trust policy:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::YOUR_SNOWFLAKE_ACCOUNT:user/YOUR_USER"
      },
      "Action": "sts:AssumeRole",
      "Condition": {
        "StringEquals": {
          "sts:ExternalId": "YOUR_EXTERNAL_ID"
        }
      }
    }
  ]
}
```

### Step 4: Create IAM Policy

Attach this policy to your IAM role:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:ListBucket",
        "s3:GetBucketLocation"
      ],
      "Resource": [
        "arn:aws:s3:::your-bucket-name/lakehouse/*",
        "arn:aws:s3:::your-bucket-name"
      ]
    }
  ]
}
```

### Step 5: Create External Stages

Run `02_external_stages.sql` in Snowflake as SYSADMIN:

```sql
USE ROLE SYSADMIN;
-- Execute the script
```

### Step 6: Test Connectivity

**Note:** Testing requires a warehouse to be running.

```sql
-- Set a warehouse
USE WAREHOUSE COMPUTE_WH;

-- List files in bronze stage
LIST @BRONZE.s3_bronze_stage;

-- List files in silver stage
LIST @SILVER.s3_silver_stage;

-- List files in gold stage
LIST @GOLD.s3_gold_stage;

-- Query data directly from stage
SELECT $1, $2, $3 
FROM @BRONZE.s3_bronze_stage 
LIMIT 10;
```

## File Formats

The stages are configured with the following file formats:

- **Bronze**: JSON with auto compression
- **Silver**: Parquet with Snappy compression
- **Gold**: Parquet with Snappy compression
- **CSV Format**: Available for CSV data ingestion

## When Do You Need a Warehouse?

### ❌ Warehouse NOT Required:
- Creating storage integrations
- Creating external stages
- Creating file formats
- Granting permissions on stages
- Describing storage integrations
- Showing stages

### ✅ Warehouse REQUIRED:
- Listing files in stages (`LIST @stage_name`)
- Loading data (`COPY INTO table FROM @stage_name`)
- Querying data from stages (`SELECT * FROM @stage_name`)
- Creating tables from stage data
- Running Snowpipe (uses serverless compute, not your warehouse)

**Best Practice:** Create storage integrations and stages first (no warehouse needed), then use a warehouse only when you need to interact with the data.

## Troubleshooting

### Error: "Access Denied"
- Verify IAM role trust policy includes Snowflake IAM user ARN
- Check IAM policy has correct S3 permissions
- Ensure bucket name and paths are correct

### Error: "Integration not found"
- Storage integration must be created by ACCOUNTADMIN
- Grant USAGE on integration to SYSADMIN

### Error: "Cannot list files"
- Verify S3 bucket exists and has files
- Check IAM role has ListBucket permission
- Ensure storage integration is properly configured

## Security Best Practices

- ✅ Use storage integration instead of AWS credentials
- ✅ Limit STORAGE_ALLOWED_LOCATIONS to specific paths
- ✅ Use STORAGE_BLOCKED_LOCATIONS to restrict sensitive paths
- ✅ Grant minimal IAM permissions (read-only for data loading)
- ✅ Enable S3 bucket encryption
- ✅ Enable S3 access logging for audit trails
