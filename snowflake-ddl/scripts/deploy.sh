#!/bin/bash
# ============================================================================
# Snowflake Deployment Script
# Description: Deploy Snowflake DDL scripts in order
# ============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Function to execute SQL file
execute_sql_file() {
    local sql_file=$1
    local file_name=$(basename "$sql_file")
    
    print_info "Executing: $sql_file"
    
    if [ ! -f "$sql_file" ]; then
        print_error "File not found: $sql_file"
        return 1
    fi
    
    # Check if file is empty or only contains comments
    if ! grep -q -v '^\s*--' "$sql_file" | grep -q '[^[:space:]]'; then
        print_warning "Skipping empty file: $file_name"
        return 0
    fi
    
    # Execute the SQL file using SnowSQL
    if snowsql -f "$sql_file" -o exit_on_error=true -o friendly=false; then
        print_success "✓ $file_name executed successfully"
        return 0
    else
        print_error "✗ Failed to execute $file_name"
        return 1
    fi
}

# Function to deploy scripts in a directory
deploy_directory() {
    local dir=$1
    local dir_name=$(basename "$dir")
    
    if [ ! -d "$dir" ]; then
        print_warning "Directory not found: $dir"
        return 0
    fi
    
    echo ""
    print_info "=========================================="
    print_info "Deploying: $dir_name"
    print_info "=========================================="
    
    # Find all SQL files in the directory and sort them
    local sql_files=$(find "$dir" -type f -name "*.sql" | sort)
    
    if [ -z "$sql_files" ]; then
        print_warning "No SQL files found in $dir_name"
        return 0
    fi
    
    # Execute each SQL file
    for sql_file in $sql_files; do
        if ! execute_sql_file "$sql_file"; then
            print_error "Deployment failed at $sql_file"
            return 1
        fi
    done
    
    print_success "✓ $dir_name deployment completed"
    return 0
}

# Main deployment function
main() {
    echo ""
    echo "╔════════════════════════════════════════╗"
    echo "║   Snowflake Deployment Script          ║"
    echo "╔════════════════════════════════════════╗"
    echo ""
    
    # Check if SnowSQL is installed
    if ! command -v snowsql &> /dev/null; then
        print_error "SnowSQL is not installed or not in PATH"
        print_info "Please install SnowSQL: https://docs.snowflake.com/en/user-guide/snowsql-install-config.html"
        exit 1
    fi
    
    # Get the script directory
    SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    SNOWFLAKE_DIR="$(dirname "$SCRIPT_DIR")"
    
    print_info "Snowflake directory: $SNOWFLAKE_DIR"
    
    # Change to snowflake directory
    cd "$SNOWFLAKE_DIR"
    
    # Define deployment order
    DEPLOYMENT_ORDER=(
        "00_account"
        "01_security"
        "02_warehouses"
        "03_databases"
        "04_storage"
        "05_schemas"
        "06_pipes"
        "07_tasks"
        "08_functions"
        "09_procedures"
    )
    
    # Deploy each directory in order
    for dir in "${DEPLOYMENT_ORDER[@]}"; do
        if ! deploy_directory "$dir"; then
            print_error "Deployment failed!"
            exit 1
        fi
    done
    
    echo ""
    print_success "=========================================="
    print_success "All deployments completed successfully!"
    print_success "=========================================="
    echo ""
}

# Run main function
main "$@"
