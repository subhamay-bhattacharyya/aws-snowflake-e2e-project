# Snowflake Deployment Scripts

This directory contains utility scripts for deploying and managing Snowflake objects.

## Prerequisites

1. **SnowSQL** must be installed and configured
   ```bash
   # Install SnowSQL
   # macOS
   brew install snowflake-snowsql
   
   # Or download from: https://docs.snowflake.com/en/user-guide/snowsql-install-config.html
   ```

2. **Configure SnowSQL connection**
   ```bash
   # Edit ~/.snowsql/config
   [connections.dev]
   accountname = your-account
   username = your-username
   password = your-password
   dbname = RAW_DB
   schemaname = PUBLIC
   warehousename = COMPUTE_WH
   ```

## Usage

### Deploy All Scripts

```bash
cd snowflake/scripts
./deploy.sh
```

This will execute all SQL scripts in the correct order:
1. Account-level objects (resource monitors, network policies)
2. Security (roles, users, grants)
3. Warehouses
4. Databases
5. Storage integrations and stages
6. Schemas and tables
7. Pipes
8. Tasks
9. Functions
10. Procedures

### Deploy Specific Directory

```bash
# Deploy only warehouses
snowsql -f ../02_warehouses/01_compute_wh.sql

# Deploy only databases
find ../03_databases -name "*.sql" -type f | sort | xargs -I {} snowsql -f {}
```

### Validate Deployment

```bash
snowsql -f validate.sql
```

### Rollback

```bash
./rollback.sh
```

## Environment Variables

You can set these environment variables to customize the deployment:

```bash
export SNOWSQL_ACCOUNT=your-account
export SNOWSQL_USER=your-username
export SNOWSQL_PWD=your-password
export SNOWSQL_DATABASE=RAW_DB
export SNOWSQL_WAREHOUSE=COMPUTE_WH
```

## Sample Deployment

The current implementation includes:
- ✅ COMPUTE_WH warehouse
- ✅ RAW_DB database with sales, marketing, finance schemas
- ✅ Sample tables: customer_orders, customer_master, product_catalog

## Troubleshooting

**Issue**: `snowsql: command not found`
- **Solution**: Install SnowSQL or add it to your PATH

**Issue**: Authentication failed
- **Solution**: Check your SnowSQL config file at `~/.snowsql/config`

**Issue**: Permission denied
- **Solution**: Make script executable: `chmod +x deploy.sh`

**Issue**: SQL execution failed
- **Solution**: Check the error message and verify your Snowflake permissions
