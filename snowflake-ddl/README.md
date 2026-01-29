# Snowflake DDL Scripts

This directory contains all Snowflake DDL scripts organized by object type and execution order.

## Directory Structure

```
snowflake/
├── environments/          # Environment-specific configurations
├── 00_account/           # Account-level objects (run first)
├── 01_security/          # Security objects (roles, users, grants)
├── 02_warehouses/        # Virtual warehouses
├── 03_databases/         # Database definitions
├── 04_storage/           # Storage integrations & stages
├── 05_schemas/           # Schema-level objects by database
├── 06_pipes/             # Snowpipe definitions
├── 07_tasks/             # Task definitions
├── 08_functions/         # UDFs and UDTFs
├── 09_procedures/        # Stored procedures
└── scripts/              # Utility scripts
```

## Execution Order

Scripts are numbered to ensure proper dependency order:
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

## Naming Conventions

### Files
- Use numbered prefixes: `01_`, `02_`, etc.
- Descriptive names: `create_database.sql`, not `db.sql`
- Lowercase with underscores

### SQL Objects
- Databases: `UPPERCASE` (e.g., `RAW_DB`, `ANALYTICS_DB`)
- Schemas: `lowercase` (e.g., `sales`, `marketing`)
- Tables: `lowercase` (e.g., `customer_orders`, `dim_customer`)
- Views: `lowercase` with `_vw` or `_v` suffix
- Materialized views: `lowercase` with `_mv` suffix

## Best Practices

1. **Idempotency**: Use `CREATE OR REPLACE` or `CREATE IF NOT EXISTS`
2. **Comments**: Add meaningful comments to all objects
3. **Testing**: Test scripts in dev before promoting to staging/prod
4. **Version Control**: All changes must go through pull requests
5. **Rollback**: Keep rollback scripts for destructive changes

## Deployment

Scripts are deployed using GitHub Actions. See `.github/workflows/snowflake-deploy.yaml` for details.
