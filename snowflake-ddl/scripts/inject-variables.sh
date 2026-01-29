#!/bin/bash
# ============================================================================
# Variable Injection Script
# Description: Inject environment-specific variables into SQL scripts
# ============================================================================

set -e

# Check arguments
if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <environment> <sql_file>"
    echo "Example: $0 dev snowflake/04_storage/aws/01_storage_integration.sql"
    exit 1
fi

ENVIRONMENT=$1
SQL_FILE=$2
ENV_FILE="snowflake/environments/${ENVIRONMENT}.env"

# Check if environment file exists
if [ ! -f "$ENV_FILE" ]; then
    echo "Error: Environment file not found: $ENV_FILE"
    exit 1
fi

# Check if SQL file exists
if [ ! -f "$SQL_FILE" ]; then
    echo "Error: SQL file not found: $SQL_FILE"
    exit 1
fi

# Load environment variables
echo "Loading configuration from: $ENV_FILE"
source "$ENV_FILE"

# Create temporary SQL file with injected variables
TEMP_SQL_FILE=$(mktemp)

# Replace variables in SQL file
sed -e "s|SET aws_role_arn = '.*';|SET aws_role_arn = '${AWS_ROLE_ARN}';|g" \
    -e "s|SET s3_bucket_name = '.*';|SET s3_bucket_name = '${S3_BUCKET_NAME}';|g" \
    "$SQL_FILE" > "$TEMP_SQL_FILE"

echo "Variables injected successfully"
echo "AWS_ROLE_ARN: ${AWS_ROLE_ARN}"
echo "S3_BUCKET_NAME: ${S3_BUCKET_NAME}"
echo "Temporary file: $TEMP_SQL_FILE"

# Output the temp file path for use in CI/CD
echo "$TEMP_SQL_FILE"
