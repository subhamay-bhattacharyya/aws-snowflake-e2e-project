#!/bin/bash
# Verification script for Terraform Codespaces setup
# Run this before executing terraform commands

set -e

echo "=========================================="
echo "Terraform Codespaces Setup Verification"
echo "=========================================="
echo ""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counters
PASS=0
FAIL=0
WARN=0

# Check function
check() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓${NC} $1"
        ((PASS++))
    else
        echo -e "${RED}✗${NC} $1"
        ((FAIL++))
    fi
}

warn() {
    echo -e "${YELLOW}⚠${NC} $1"
    ((WARN++))
}

# 1. Check we're in the right directory
echo "1. Checking directory..."
if [ -f "providers.tf" ] && [ -f "main.tf" ] && [ -f "variables.tf" ]; then
    check "In correct directory (infra/aws/tf)"
else
    echo -e "${RED}✗${NC} Not in correct directory"
    echo "Please run: cd infra/aws/tf"
    exit 1
fi
echo ""

# 2. Check Snowflake environment variables
echo "2. Checking Snowflake secrets..."

if [ -n "$TF_VAR_SNOWFLAKE_ACCOUNT" ] || [ -n "$TF_VAR_snowflake_account" ]; then
    check "TF_VAR_SNOWFLAKE_ACCOUNT is set"
    echo "   Account: ${TF_VAR_SNOWFLAKE_ACCOUNT:0:5}..."
else
    echo -e "${RED}✗${NC} TF_VAR_SNOWFLAKE_ACCOUNT not set"
    ((FAIL++))
fi

if [ -n "$TF_VAR_SNOWFLAKE_USER" ] || [ -n "$TF_VAR_snowflake_user" ]; then
    check "TF_VAR_SNOWFLAKE_USER is set"
    echo "   User: ${TF_VAR_SNOWFLAKE_USER}"
else
    echo -e "${RED}✗${NC} TF_VAR_SNOWFLAKE_USER not set"
    ((FAIL++))
fi

if [ -n "$TF_VAR_SNOWFLAKE_PRIVATE_KEY" ] || [ -n "$TF_VAR_snowflake_private_key" ]; then
    check "TF_VAR_SNOWFLAKE_PRIVATE_KEY is set"
    KEY_VAR="${TF_VAR_SNOWFLAKE_PRIVATE_KEY:-$TF_VAR_snowflake_private_key}"
    echo "   Length: ${#KEY_VAR} characters"
    
    # Check if it looks like a valid PEM key
    if echo "$KEY_VAR" | grep -q "BEGIN PRIVATE KEY"; then
        check "Private key has correct format (PEM)"
    else
        echo -e "${RED}✗${NC} Private key missing header (should start with -----BEGIN PRIVATE KEY-----)"
        ((FAIL++))
    fi
else
    echo -e "${RED}✗${NC} TF_VAR_SNOWFLAKE_PRIVATE_KEY not set"
    ((FAIL++))
fi

if [ -n "$TF_VAR_SNOWFLAKE_ROLE" ] || [ -n "$TF_VAR_snowflake_role" ]; then
    check "TF_VAR_SNOWFLAKE_ROLE is set"
    echo "   Role: ${TF_VAR_SNOWFLAKE_ROLE}"
else
    echo -e "${RED}✗${NC} TF_VAR_SNOWFLAKE_ROLE not set"
    ((FAIL++))
fi
echo ""

# 3. Check AWS environment variables
echo "3. Checking AWS secrets..."

if [ -n "$AWS_ACCESS_KEY_ID" ]; then
    check "AWS_ACCESS_KEY_ID is set"
    echo "   Key: ${AWS_ACCESS_KEY_ID:0:10}..."
else
    echo -e "${RED}✗${NC} AWS_ACCESS_KEY_ID not set"
    ((FAIL++))
fi

if [ -n "$AWS_SECRET_ACCESS_KEY" ]; then
    check "AWS_SECRET_ACCESS_KEY is set"
    echo "   Length: ${#AWS_SECRET_ACCESS_KEY} characters"
else
    echo -e "${RED}✗${NC} AWS_SECRET_ACCESS_KEY not set"
    ((FAIL++))
fi

if [ -n "$AWS_DEFAULT_REGION" ]; then
    check "AWS_DEFAULT_REGION is set"
    echo "   Region: ${AWS_DEFAULT_REGION}"
else
    echo -e "${RED}✗${NC} AWS_DEFAULT_REGION not set"
    ((FAIL++))
fi
echo ""

# 4. Check required files
echo "4. Checking configuration files..."

[ -f "input-jsons/warehouses.json" ] && check "warehouses.json exists" || { echo -e "${RED}✗${NC} warehouses.json not found"; ((FAIL++)); }
[ -f "modules/snowflake/main.tf" ] && check "Snowflake module exists" || { echo -e "${RED}✗${NC} Snowflake module not found"; ((FAIL++)); }
[ -f "modules/snowflake/modules/warehouse/main.tf" ] && check "Warehouse sub-module exists" || { echo -e "${RED}✗${NC} Warehouse sub-module not found"; ((FAIL++)); }
echo ""

# 5. Check Terraform installation
echo "5. Checking Terraform..."

if command -v terraform &> /dev/null; then
    check "Terraform is installed"
    TERRAFORM_VERSION=$(terraform version -json | grep -o '"terraform_version":"[^"]*"' | cut -d'"' -f4)
    echo "   Version: $TERRAFORM_VERSION"
else
    echo -e "${RED}✗${NC} Terraform not installed"
    ((FAIL++))
fi
echo ""

# 6. Check if Terraform is initialized
echo "6. Checking Terraform initialization..."

if [ -d ".terraform" ]; then
    check "Terraform is initialized (.terraform directory exists)"
else
    warn "Terraform not initialized yet (run: terraform init)"
fi
echo ""

# 7. Validate JSON syntax
echo "7. Validating JSON files..."

if command -v jq &> /dev/null; then
    if jq empty input-jsons/warehouses.json 2>/dev/null; then
        check "warehouses.json has valid JSON syntax"
    else
        echo -e "${RED}✗${NC} warehouses.json has invalid JSON syntax"
        ((FAIL++))
    fi
else
    warn "jq not installed, skipping JSON validation"
fi
echo ""

# Summary
echo "=========================================="
echo "Summary"
echo "=========================================="
echo -e "${GREEN}Passed:${NC} $PASS"
echo -e "${YELLOW}Warnings:${NC} $WARN"
echo -e "${RED}Failed:${NC} $FAIL"
echo ""

if [ $FAIL -eq 0 ]; then
    echo -e "${GREEN}✓ All checks passed! You're ready to run Terraform.${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. terraform init     # Initialize Terraform"
    echo "  2. terraform validate # Validate configuration"
    echo "  3. terraform plan     # Preview changes"
    echo "  4. terraform apply    # Create resources"
    exit 0
else
    echo -e "${RED}✗ Some checks failed. Please fix the issues above.${NC}"
    echo ""
    echo "Common fixes:"
    echo "  - Add missing secrets in: Settings → Secrets and variables → Codespaces"
    echo "  - Restart your Codespace to load new secrets"
    echo "  - Verify secret names have TF_VAR_ prefix"
    echo ""
    echo "See PRE_FLIGHT_CHECKLIST.md for detailed instructions."
    exit 1
fi
