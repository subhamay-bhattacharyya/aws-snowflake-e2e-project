# Environment Configuration

This directory contains environment-specific configuration files for Snowflake deployments.

## Best Practices for Passing Variables

### Option 1: Environment Files (Recommended for Multiple Environments)

**Pros:**
- ✅ Clear separation of environments (dev, staging, prod)
- ✅ Easy to version control (with proper .gitignore)
- ✅ Simple to switch between environments
- ✅ Works well with CI/CD pipelines

**Setup:**

1. Create environment-specific files:
   ```
   snowflake/environments/
   ├── dev.env
   ├── staging.env
   └── prod.env
   ```

2. Add sensitive values to `.gitignore`:
   ```
   snowflake/environments/*.env
   ```

3. Create `.env.example` template:
   ```bash
   AWS_ROLE_ARN=arn:aws:iam::ACCOUNT_ID:role/ROLE_NAME
   S3_BUCKET_NAME=bucket-name
   AWS_REGION=us-east-1
   ENVIRONMENT=dev
   ```

4. Use the injection script:
   ```bash
   ./snowflake/scripts/inject-variables.sh dev snowflake/04_storage/aws/01_storage_integration.sql
   ```

### Option 2: GitHub Actions Variables (Recommended for CI/CD)

**Pros:**
- ✅ Secure storage in GitHub
- ✅ No sensitive data in repository
- ✅ Environment-specific secrets
- ✅ Easy rotation and management

**Setup:**

1. Add GitHub Actions Variables:
   - Go to: Settings → Secrets and variables → Actions → Variables
   - Add variables:
     - `AWS_ROLE_ARN_DEV`
     - `AWS_ROLE_ARN_PROD`
     - `S3_BUCKET_NAME_DEV`
     - `S3_BUCKET_NAME_PROD`

2. Update workflow to inject variables:
   ```yaml
   - name: Inject Variables
     run: |
       sed -i "s|SET aws_role_arn = '.*';|SET aws_role_arn = '${{ vars.AWS_ROLE_ARN_DEV }}';|g" \
         snowflake/04_storage/aws/01_storage_integration.sql
       sed -i "s|SET s3_bucket_name = '.*';|SET s3_bucket_name = '${{ vars.S3_BUCKET_NAME_DEV }}';|g" \
         snowflake/04_storage/aws/01_storage_integration.sql
   ```

### Option 3: Snowflake Session Variables (Simple Approach)

**Pros:**
- ✅ No external dependencies
- ✅ Works directly in Snowflake
- ✅ Good for manual deployments

**Usage:**

```sql
-- Set variables at the beginning of your session
SET aws_role_arn = 'arn:aws:iam::123456789012:role/my-role';
SET s3_bucket_name = 'my-bucket';

-- Then run your DDL scripts
-- Variables will be used automatically
```

### Option 4: Terraform/IaC Integration (Advanced)

**Pros:**
- ✅ Infrastructure and configuration as code
- ✅ Automatic resource creation
- ✅ State management
- ✅ Dependency tracking

**Setup:**

Use Terraform to create AWS resources and pass values to Snowflake:

```hcl
resource "snowflake_storage_integration" "aws_s3" {
  name    = "aws_s3_integration"
  type    = "EXTERNAL_STAGE"
  enabled = true
  
  storage_provider         = "S3"
  storage_aws_role_arn     = aws_iam_role.snowflake_role.arn
  storage_allowed_locations = [
    "s3://${aws_s3_bucket.lakehouse.id}/lakehouse/bronze/",
    "s3://${aws_s3_bucket.lakehouse.id}/lakehouse/silver/",
    "s3://${aws_s3_bucket.lakehouse.id}/lakehouse/gold/"
  ]
}
```

## Comparison Matrix

| Approach | Security | Flexibility | CI/CD Ready | Complexity |
|----------|----------|-------------|-------------|------------|
| Environment Files | Medium | High | Yes | Low |
| GitHub Actions Variables | High | High | Yes | Low |
| Session Variables | Low | Low | No | Very Low |
| Terraform/IaC | High | Very High | Yes | High |

## Recommended Approach by Use Case

### Local Development
- Use environment files (`dev.env`)
- Keep files out of git with `.gitignore`

### CI/CD Pipeline
- Use GitHub Actions Variables
- Inject at deployment time
- Different variables per environment

### Production
- Use GitHub Actions Secrets (not Variables) for sensitive data
- Combine with environment files for non-sensitive config
- Enable branch protection rules

### Enterprise/Multi-Cloud
- Use Terraform or similar IaC tool
- Centralized configuration management
- Automated resource provisioning

## Security Best Practices

1. **Never commit sensitive values**
   ```bash
   # Add to .gitignore
   *.env
   !*.env.example
   ```

2. **Use GitHub Secrets for sensitive data**
   - AWS credentials
   - Snowflake private keys
   - Production ARNs

3. **Use GitHub Variables for non-sensitive config**
   - Bucket names
   - Region names
   - Environment identifiers

4. **Rotate credentials regularly**
   - Update GitHub Secrets
   - Update IAM roles
   - Regenerate Snowflake keys

5. **Use least privilege**
   - Minimal IAM permissions
   - Read-only S3 access for data loading
   - Separate roles per environment

## Example Workflow Integration

```yaml
jobs:
  deploy-storage:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
      
      - name: Inject Variables
        run: |
          # Replace placeholders with actual values
          sed -i "s|SET aws_role_arn = '.*';|SET aws_role_arn = '${{ vars.AWS_ROLE_ARN }}';|g" \
            snowflake/04_storage/aws/01_storage_integration.sql
          sed -i "s|SET s3_bucket_name = '.*';|SET s3_bucket_name = '${{ vars.S3_BUCKET_NAME }}';|g" \
            snowflake/04_storage/aws/01_storage_integration.sql
      
      - name: Deploy Storage Integration
        uses: subhamay-bhattacharyya-gha/snowflake-run-ddl-action@v1
        with:
          account: ${{ vars.SNOWFLAKE_ACCOUNT }}
          user: ${{ vars.SNOWFLAKE_USER }}
          private_key: ${{ secrets.SNOWFLAKE_PRIVATE_KEY }}
          role: ACCOUNTADMIN
          script: snowflake/04_storage/aws/01_storage_integration.sql
```

## Migration Path

If you're currently using hardcoded values:

1. **Extract values** to environment files
2. **Test locally** with injection script
3. **Add to GitHub** as Variables/Secrets
4. **Update workflow** to inject variables
5. **Remove hardcoded values** from SQL files
6. **Document** the configuration in README

## Support

For questions or issues:
- Check the main README.md
- Review GitHub Actions logs
- Verify environment file format
- Test injection script locally
