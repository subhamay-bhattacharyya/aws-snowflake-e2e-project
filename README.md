# Snowflake Lakehouse

![Built with Kiro](https://img.shields.io/badge/Built_with-Kiro-8845f4?logo=robot&logoColor=white)&nbsp;![Commit Activity](https://img.shields.io/github/commit-activity/t/subhamay-bhattacharyya/aws-snowflake-e2e-project)&nbsp;![Last Commit](https://img.shields.io/github/last-commit/subhamay-bhattacharyya/aws-snowflake-e2e-project)&nbsp;![Release Date](https://img.shields.io/github/release-date/subhamay-bhattacharyya/aws-snowflake-e2e-project)&nbsp;![Repo Size](https://img.shields.io/github/repo-size/subhamay-bhattacharyya/aws-snowflake-e2e-project)&nbsp;![File Count](https://img.shields.io/github/directory-file-count/subhamay-bhattacharyya/aws-snowflake-e2e-project)&nbsp;![Issues](https://img.shields.io/github/issues/subhamay-bhattacharyya/aws-snowflake-e2e-project)&nbsp;![Top Language](https://img.shields.io/github/languages/top/subhamay-bhattacharyya/aws-snowflake-e2e-project)&nbsp;![Custom Endpoint](https://img.shields.io/endpoint?url=https://gist.githubusercontent.com/bsubhamay/afb632c4d78d83fbc1e6b4486d5720a4/raw/aws-snowflake-e2e-project.json?)

A Snowflake Lakehouse implementation with AWS and Infrastructure as Code (Terraform), automated deployment using GitHub Actions.

## Overview

This repository tracks the build of an end-to-end Snowflake data engineering solution—from source data analysis and ingestion design to layered stage/raw/curated modeling, automation with DAG + GitHub Actions, dynamic tables, and Streamlit dashboards—using Snowpark Python and marketplace datasets.

The project demonstrates a complete data lakehouse implementation with:

- **Infrastructure as Code**: Terraform configurations for AWS (S3, IAM) and Snowflake resources
- **Layered Data Architecture**: Stage → Raw → Curated data modeling pattern
- **Automated Ingestion**: Snowpipe for real-time data loading from S3
- **Data Transformation**: Snowpark Python for ETL/ELT processing
- **Orchestration**: DAG-based workflows with GitHub Actions CI/CD
- **Dynamic Tables**: Incremental data processing with automatic refresh
- **Visualization**: Streamlit dashboards for data exploration
- **Marketplace Integration**: Leveraging Snowflake marketplace datasets

## Repository Structure

```
.
├── infra/                          # Infrastructure as Code (Terraform)
│   ├── platform/tf/                # Root orchestration module (entry point)
│   │   ├── main.tf                 # Orchestrates AWS + Snowflake modules
│   │   ├── locals.tf               # Configuration parsing from JSON
│   │   ├── variables.tf            # Input variables
│   │   ├── outputs.tf              # Module outputs
│   │   ├── versions.tf             # Provider version constraints
│   │   ├── backend.tf              # Terraform Cloud backend
│   │   ├── providers-aws.tf        # AWS provider configuration
│   │   └── providers-snowflake.tf  # Snowflake provider configuration
│   ├── aws/tf/                     # AWS child module
│   │   ├── main.tf                 # S3 bucket + IAM role orchestration
│   │   ├── modules/                # Nested modules (s3, iam, iam_role_final, s3_event_notification)
│   │   └── templates/              # Bucket policy templates
│   └── snowflake/tf/               # Snowflake child module
│       ├── main.tf                 # Warehouses, databases, stages, pipes
│       └── modules/                # Nested modules (warehouse, database, stage, etc.)
├── input-jsons/                    # Configuration files
│   ├── aws/config.json             # AWS resource configuration
│   └── snowflake/config.json       # Snowflake resource configuration
├── snowflake-ddl/                  # Snowflake DDL Scripts
│   ├── 00_account/                 # Account-level objects (resource monitors, network policies)
│   ├── 01_security/                # Roles, users, grants
│   ├── 02_warehouses/              # Virtual warehouses
│   ├── 03_databases/               # Database definitions
│   ├── 04_storage/                 # Storage integrations & external stages
│   ├── 05_schemas/                 # Schema-level objects (tables, views)
│   ├── 06_pipes/                   # Snowpipe definitions
│   ├── 07_tasks/                   # Task definitions
│   ├── 08_functions/               # UDFs and UDTFs
│   ├── 09_procedures/              # Stored procedures
│   ├── environments/               # Environment configs (dev/staging/prod)
│   └── scripts/                    # Utility scripts (deploy, rollback, validate)
├── .github/
│   └── workflows/                  # GitHub Actions workflows (ci.yaml, etc.)
├── .devcontainer/                  # Dev container configuration
├── cliff.toml                      # git-cliff changelog configuration
└── utils/                          # Utility scripts
```

## Architecture

This project uses a **4-phase architecture**:

### Phase 1: AWS Resources
- S3 Bucket for data storage
- IAM Role with placeholder trust policy

### Phase 2: Snowflake Resources
- Warehouses, Databases, Schemas
- File Formats, Storage Integration
- External Stages, Tables, Snowpipes

### Phase 3: AWS Trust Policy Update
- Update IAM Role trust policy with Snowflake's IAM User ARN and External ID

### Phase 4: S3 Event Notifications
- Configure S3 bucket notifications to trigger Snowpipe auto-ingest

## Getting Started

### Prerequisites

- **Terraform** >= 1.0
- **Snowflake Account** with appropriate permissions
- **AWS Account** with IAM permissions
- **GitHub Repository** with Actions enabled

#### One-Time Snowflake Setup

Before using this action, run the following SQL script in Snowflake to create the utility infrastructure (only needs to be run once):

**Step 1: Create Utility Infrastructure**

```sql
-- =========================================================
-- Snowflake Utility Setup for DDL Migrations
-- =========================================================
-- This script creates:
--   1. A dedicated warehouse for CI/CD metadata operations
--   2. Utility database (UTIL_DB)
--   3. Utility schema (UTIL_SCHEMA)
--   4. DDL migration history table
--
-- Safe to re-run (idempotent)
-- =========================================================

-- -----------------------------------------------------------
-- 1. Create and use a dedicated warehouse
-- -----------------------------------------------------------
CREATE WAREHOUSE IF NOT EXISTS UTIL_WH
  WAREHOUSE_SIZE = 'XSMALL'
  WAREHOUSE_TYPE = 'STANDARD'
  AUTO_SUSPEND = 60
  AUTO_RESUME = TRUE
  INITIALLY_SUSPENDED = TRUE
  COMMENT = 'Warehouse for CI/CD utility operations and DDL migration tracking';

USE WAREHOUSE UTIL_WH;

-- -----------------------------------------------------------
-- 2. Create utility database and schema
-- -----------------------------------------------------------
CREATE DATABASE IF NOT EXISTS UTIL_DB
  COMMENT = 'Utility database for CI/CD metadata and migration tracking';

CREATE SCHEMA IF NOT EXISTS UTIL_DB.UTIL_SCHEMA
  COMMENT = 'Utility schema for migration and operational tables';

-- -----------------------------------------------------------
-- 3. Create DDL migration history table
-- -----------------------------------------------------------
CREATE TABLE IF NOT EXISTS UTIL_DB.UTIL_SCHEMA.DDL_MIGRATION_HISTORY (
  script_name    STRING        NOT NULL,
  script_path    STRING        NOT NULL,
  checksum       STRING        NOT NULL,
  applied_at     TIMESTAMP_LTZ NOT NULL DEFAULT CURRENT_TIMESTAMP(),
  status         STRING        NOT NULL,
  error_message  STRING,
  run_id         STRING,
  actor          STRING
) COMMENT = 'Tracks executed Snowflake DDL migration scripts for CI/CD pipelines';

-- -----------------------------------------------------------
-- 4. (Optional) Verify creation
-- -----------------------------------------------------------
SELECT
  'UTIL_DB.UTIL_SCHEMA.DDL_MIGRATION_HISTORY created successfully' AS status,
  CURRENT_TIMESTAMP() AS verified_at;
```

**Step 2: Grant MANAGE GRANTS Privilege to SYSADMIN**

SYSADMIN needs the MANAGE GRANTS privilege to grant permissions to other roles like PUBLIC. Run this as ACCOUNTADMIN:

```sql
USE ROLE ACCOUNTADMIN;

-- Grant MANAGE GRANTS privilege to SYSADMIN
-- This allows SYSADMIN to grant privileges on objects it owns
GRANT MANAGE GRANTS ON ACCOUNT TO ROLE SYSADMIN;

-- Verify the grant
SHOW GRANTS TO ROLE SYSADMIN;
```

**Note:** With this setup, SYSADMIN can both create objects and manage their permissions, simplifying the deployment process.

**Note:** If you want to use a different database/schema/table name, you can customize it using the `migrations_table` input parameter in the GitHub Actions workflow.

### 1. Create Dedicated Service Account

For security best practices, create a dedicated service account for GitHub Actions instead of using your personal account.

#### Step 1: Generate Key Pair

On your local machine, generate an RSA key pair:

**Option A: Without Passphrase (Recommended for CI/CD)**
```bash
# Generate unencrypted PKCS8 private key (no passphrase)
openssl genrsa 2048 | openssl pkcs8 -topk8 -inform PEM -out snowflake_key.p8 -nocrypt

# Generate public key
openssl rsa -in snowflake_key.p8 -pubout -out snowflake_key.pub
```

**Option B: With Passphrase (For enhanced security)**
```bash
# Generate encrypted PKCS8 private key (with passphrase)
openssl genrsa 2048 | openssl pkcs8 -topk8 -inform PEM -out snowflake_key.p8 -v2 aes-256-cbc

# Generate public key
openssl rsa -in snowflake_key.p8 -pubout -out snowflake_key.pub
```

**Extract public key value** (for both options):
```bash
# Remove header/footer and newlines for Snowflake
grep -v "BEGIN PUBLIC" snowflake_key.pub | grep -v "END PUBLIC" | tr -d '\n'
```

**Save the output** - you'll need it for the next step.

**Note:** If using a passphrase, you'll need to provide `SNOWFLAKE_PRIVATE_KEY_PASSPHRASE` as an additional secret.

#### Step 2: Create Service Account in Snowflake

Run this SQL in Snowflake (replace `YOUR_PUBLIC_KEY_HERE` with the output from Step 1):

```sql
-- =========================================================
-- Create Service Account for GitHub Actions
-- =========================================================

-- Create dedicated service account
CREATE USER IF NOT EXISTS GH_ACTIONS_USER
  RSA_PUBLIC_KEY = 'YOUR_PUBLIC_KEY_HERE'
  DEFAULT_ROLE = SYSADMIN
  DEFAULT_WAREHOUSE = COMPUTE_WH
  MUST_CHANGE_PASSWORD = FALSE
  COMMENT = 'Service account for GitHub Actions CI/CD deployments';

-- Grant SYSADMIN role (for DDL and grant operations)
GRANT ROLE SYSADMIN TO USER GH_ACTIONS_USER;

-- Grant usage on warehouses
GRANT USAGE ON WAREHOUSE UTIL_WH TO ROLE SYSADMIN;
GRANT USAGE ON WAREHOUSE COMPUTE_WH TO ROLE SYSADMIN;

-- Grant usage on the utility database
GRANT USAGE ON DATABASE UTIL_DB TO ROLE SYSADMIN;
GRANT USAGE ON SCHEMA UTIL_DB.UTIL_SCHEMA TO ROLE SYSADMIN;

-- Grant create privileges for the migration table
GRANT CREATE TABLE ON SCHEMA UTIL_DB.UTIL_SCHEMA TO ROLE SYSADMIN;

-- Grant all privileges on the migration table (if it already exists)
GRANT ALL PRIVILEGES ON TABLE UTIL_DB.UTIL_SCHEMA.DDL_MIGRATION_HISTORY TO ROLE SYSADMIN;

-- If the user needs to create the database/schema (first run)
GRANT CREATE DATABASE ON ACCOUNT TO ROLE SYSADMIN;

-- Verify the user's role
DESC USER GH_ACTIONS_USER;

-- See what roles the user has
SHOW GRANTS TO USER GH_ACTIONS_USER;

-- See what the SYSADMIN role can do
SHOW GRANTS TO ROLE SYSADMIN;

```

**Security Notes:**
- ✅ Use `SYSADMIN` role for all DDL and grant operations
- ✅ Grant `MANAGE GRANTS` privilege to SYSADMIN for permission management
- ✅ Key-pair authentication is more secure than passwords
- ✅ Service accounts provide better audit trails
- ✅ Never commit private keys to the repository

### 2. Configure GitHub Secrets and Variables

Set up GitHub Actions authentication. Navigate to **Settings → Secrets and variables → Actions**.

#### Required Repository Variables

| Variable Name | Description | Example |
|---------------|-------------|---------|
| `SNOWFLAKE_ORGANIZATION_NAME` | Snowflake organization name | `AGXUOKJ` |
| `SNOWFLAKE_ACCOUNT_NAME` | Snowflake account name | `JKC15404` |
| `SNOWFLAKE_USER` | Service account username | `GH_ACTIONS_USER` |
| `SNOWFLAKE_ROLE` | Snowflake role for deployments | `SYSADMIN` |
| `AWS_REGION` | AWS region for resources | `us-east-1` |
| `TF_LINT_VER` | TFLint version (optional) | `v0.50.0` |

#### Required Repository Secrets

| Secret Name | Description |
|-------------|-------------|
| `SNOWFLAKE_PRIVATE_KEY` | Content of `snowflake_key.p8` file (including `-----BEGIN/END PRIVATE KEY-----` headers) |
| `TF_TOKEN_APP_TERRAFORM_IO` | Terraform Cloud API token for remote backend |
| `AWS_OIDC_ROLE_ARN` | AWS IAM role ARN for OIDC authentication (e.g., `arn:aws:iam::123456789012:role/github-actions-role`) |

#### How to Get These Values

**Snowflake Variables:**
1. Log into Snowflake
2. Organization name: Found in your account URL (`https://<org>-<account>.snowflakecomputing.com`)
3. Account name: Same as above
4. User/Role: Created in the service account setup (Step 1)

**Snowflake Private Key:**
1. Generated in Step 1 (`snowflake_key.p8`)
2. Copy the entire file content including headers

**Terraform Cloud Token:**
1. Go to [Terraform Cloud](https://app.terraform.io)
2. Navigate to **User Settings → Tokens**
3. Create a new API token

**AWS OIDC Role ARN:**
1. Set up OIDC in AWS (see [AWS OIDC Setup](#3-aws-oidc-setup-optional-but-recommended))
2. Copy the IAM role ARN

### 2a. Configure Codespaces Secrets (For Terraform Development)

If you're running Terraform from GitHub Codespaces, you need to configure Codespaces secrets for authentication.

**Quick setup:**

Navigate to: **Settings → Secrets and variables → Codespaces**

Add these secrets:

**Snowflake Authentication:**
| Secret Name | Description |
|-------------|-------------|
| `TF_VAR_snowflake_organization_name` | Snowflake organization name |
| `TF_VAR_snowflake_account_name` | Snowflake account name |
| `TF_VAR_snowflake_user` | Snowflake username |
| `TF_VAR_snowflake_private_key` | Content of `snowflake_key.p8` |
| `TF_VAR_snowflake_role` | Set to `SYSADMIN` |

**AWS Authentication:**
| Secret Name | Description |
|-------------|-------------|
| `AWS_ACCESS_KEY_ID` | From AWS IAM |
| `AWS_SECRET_ACCESS_KEY` | From AWS IAM |
| `AWS_DEFAULT_REGION` | e.g., `us-east-1` |

**Note:** GitHub Actions secrets and Codespaces secrets are stored separately. You need to configure both, but you can use the same values.

### 3. AWS OIDC Setup (Optional but Recommended)

For secure GitHub Actions authentication with AWS without long-lived credentials, set up OIDC (OpenID Connect). This eliminates the need to store AWS access keys in GitHub Secrets.

**See detailed setup instructions:** [infra/aws/README.md](infra/aws/README.md)

**Benefits:**
- ✅ No AWS access keys stored in GitHub Secrets
- ✅ Short-lived tokens that expire automatically
- ✅ Improved security posture
- ✅ Recommended by AWS and GitHub

## Snowflake Object Organization

Scripts are organized by execution order:

1. **00_account**: Resource monitors, network policies
2. **01_security**: Roles, users, grants
3. **02_warehouses**: Virtual warehouses
4. **03_databases**: Database creation
5. **04_storage**: Storage integrations and external stages
6. **05_schemas**: Tables, views, streams
7. **06_pipes**: Snowpipe for automated ingestion
8. **07_tasks**: Scheduled tasks
9. **08_functions**: User-defined functions
10. **09_procedures**: Stored procedures

## Sample Implementation

The repository includes sample implementations:

- **Warehouse**: `COMPUTE_WH` (small, auto-suspend)
- **Database**: `RAW_DB` with sales, marketing, finance schemas
- **Tables**: 
  - `customer_orders` - Order transactions
  - `customer_master` - Customer data
  - `product_catalog` - Product information

## GitHub Actions Workflow

The deployment workflow (`snowflake-deploy.yaml`) automatically:

- Discovers all SQL files in the repository
- Deploys them in dependency order
- Runs files in parallel within each stage
- Uses the reusable action: `subhamay-bhattacharyya-gha/snowflake-run-ddl-action`

**Triggers**:
- Push to `main` or `develop` branches (when `snowflake/**` files change)
- Pull requests to `main` or `develop`
- Manual workflow dispatch

## Best Practices

### Migration Tracking

By default, the action tracks which scripts have been applied using a migrations table. This enables:

- **Idempotent execution**: Scripts are only run once (based on path + checksum)
- **Change detection**: If a script's content changes, it will be re-run
- **Audit trail**: Complete history of what was applied, when, and by whom

#### Migration Table Schema

The default table `UTIL_DB.UTIL_SCHEMA.DDL_MIGRATION_HISTORY` contains:

- `script_name` - Filename of the script
- `script_path` - Full path to the script
- `checksum` - SHA-256 hash of the script content
- `applied_at` - Timestamp when applied
- `status` - SUCCESS or FAILED
- `error_message` - Error details if failed
- `run_id` - GitHub Actions run ID
- `actor` - GitHub user who triggered the run

#### Baseline Mode

Use baseline mode to mark existing scripts as applied without executing them. This is useful when:

- Adopting this action in an existing environment
- Scripts have already been manually applied
- You want to start tracking from a known state

To enable baseline mode in the workflow:

```yaml
- name: Deploy with baseline
  uses: subhamay-bhattacharyya-gha/snowflake-run-ddl-action@v1
  with:
    baseline: true
    # ... other parameters
```

#### Disabling Migration Tracking

To run scripts without tracking (not recommended for production):

```yaml
- name: Deploy without tracking
  uses: subhamay-bhattacharyya-gha/snowflake-run-ddl-action@v1
  with:
    track_migrations: false
    # ... other parameters
```

### SQL Scripts
- Use `CREATE OR REPLACE` or `CREATE IF NOT EXISTS` for idempotency
- Add meaningful comments to all objects
- Number files for execution order (01_, 02_, etc.)
- Test in dev before promoting to staging/prod

### Security
- Never commit credentials or private keys
- Use service accounts for automation
- Implement least privilege access
- Rotate keys regularly

### Infrastructure
- Use remote state storage for Terraform
- Enable state locking
- Tag all resources consistently
- Use separate environments (dev/staging/prod)

## Documentation

- [Infrastructure Setup](infra/README.md)
- [Snowflake DDL Scripts](snowflake/README.md)
- [GitHub Actions Setup](.github/SETUP.md)
- [Deployment Scripts](snowflake/scripts/README.md)

## Contributing

### Commit Message Convention

This project uses [Conventional Commits](https://www.conventionalcommits.org/) for automated changelog generation. Please format your commit messages as follows:

```
<type>: <description>

[optional body]
```

#### Commit Types

| Type | Description | Example |
|------|-------------|---------|
| `feat` | New feature or functionality | `feat: add Azure storage integration support` |
| `fix` | Bug fix | `fix: correct IAM trust policy condition` |
| `docs` | Documentation changes | `docs: update README with setup instructions` |
| `style` | Code style changes (formatting, whitespace) | `stylhttps://agxuokj-jkc15404.snowflakecomputing.com/console/login?activationToken=ver%3A1-hint%3A344489740-ETMsDgAAAZuzoPggABRBRVMvQ0JDL1BLQ1M1UGFkZGluZwEAABAAEBldmu8VANRBCTUgQE%2F7RGgAAABg%2Bi1xEnXGEcqx%2BVMauNO9GmzhCnHTRbWhExX%2Ftsk%2BfZHPKbTjNV61u9%2B%2BjuAiPOgpm%2FYk6MsqkwrbcUM5%2F9LYDHnEoUuMjYN5A7MZDQWpWfx2y6ERIZO3Uq1CuKFbCZbEABTZyEHS0WcfOoqbc3Dw6%2FyEs1zyow%3D%3De: fix indentation in main.tf` |
| `refactor` | Code refactoring without feature changes | `refactor: simplify locals.tf configuration` |
| `perf` | Performance improvements | `perf: optimize S3 bucket policy lookup` |
| `test` | Adding or updating tests | `test: add validation for warehouse config` |
| `chore` | Maintenance tasks, dependencies | `chore: update Terraform provider versions` |
| `ci` | CI/CD configuration changes | `ci: add changelog generation to workflow` |

#### Examples

```bash
# Feature
git commit -m "feat: add Snowpipe auto-ingest configuration"

# Bug fix
git commit -m "fix: resolve storage integration ARN reference"

# Documentation
git commit -m "docs: add commit message guidelines to README"

# With scope (optional)
git commit -m "feat(snowflake): add file format support for Parquet"

# With breaking change
git commit -m "feat!: change storage integration naming convention"
```

#### Why This Matters

- Commits are automatically categorized in the changelog
- Release notes are generated from commit messages
- Makes it easier to understand project history
- Enables semantic versioning automation

### Development Workflow

1. Create a feature branch from `main`
2. Make your changes
3. Test in dev environment
4. Create a pull request with description
5. Wait for approval and automated deployment

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines.

## License

MIT License - See [LICENSE](LICENSE) for details.

## Support

For issues and questions:
- Open an issue in this repository
- Check existing documentation in the `docs/` folder
- Review [Snowflake documentation](https://docs.snowflake.com/)

## Roadmap

- [ ] Add data quality checks
- [ ] Implement dbt integration
- [ ] Add monitoring and alerting
- [ ] Create CI/CD for data pipelines
- [ ] Add Streamlit dashboards
- [ ] Implement dynamic tables