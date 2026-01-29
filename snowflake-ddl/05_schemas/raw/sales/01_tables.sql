-- ============================================================================
-- Raw Sales Tables
-- Description: Tables for raw sales data
-- ============================================================================

USE DATABASE RAW_DB;
USE SCHEMA sales;

-- Sample table: Customer Orders
CREATE OR REPLACE TABLE customer_orders (
    order_id VARCHAR(50) NOT NULL,
    customer_id VARCHAR(50) NOT NULL,
    order_date TIMESTAMP_NTZ NOT NULL,
    order_amount DECIMAL(18,2),
    order_status VARCHAR(20),
    product_category VARCHAR(50),
    product_name VARCHAR(200),
    quantity INTEGER,
    unit_price DECIMAL(18,2),
    discount_amount DECIMAL(18,2) DEFAULT 0.00,
    tax_amount DECIMAL(18,2) DEFAULT 0.00,
    shipping_address VARCHAR(500),
    billing_address VARCHAR(500),
    payment_method VARCHAR(50),
    region VARCHAR(50),
    country VARCHAR(50),
    created_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    updated_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    source_system VARCHAR(50) DEFAULT 'ERP',
    CONSTRAINT pk_customer_orders PRIMARY KEY (order_id)
)
CLUSTER BY (order_date, region)
COMMENT = 'Raw customer orders from source ERP system';

-- Sample table: Customer Master
CREATE OR REPLACE TABLE customer_master (
    customer_id VARCHAR(50) NOT NULL,
    customer_name VARCHAR(200) NOT NULL,
    email VARCHAR(200),
    phone VARCHAR(50),
    customer_type VARCHAR(50),
    customer_segment VARCHAR(50),
    registration_date DATE,
    status VARCHAR(20),
    address VARCHAR(500),
    city VARCHAR(100),
    state VARCHAR(100),
    country VARCHAR(50),
    postal_code VARCHAR(20),
    created_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    updated_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    CONSTRAINT pk_customer_master PRIMARY KEY (customer_id)
)
COMMENT = 'Raw customer master data';

-- Sample table: Product Catalog
CREATE OR REPLACE TABLE product_catalog (
    product_id VARCHAR(50) NOT NULL,
    product_name VARCHAR(200) NOT NULL,
    product_category VARCHAR(50),
    product_subcategory VARCHAR(50),
    brand VARCHAR(100),
    unit_price DECIMAL(18,2),
    cost_price DECIMAL(18,2),
    stock_quantity INTEGER,
    reorder_level INTEGER,
    supplier_id VARCHAR(50),
    status VARCHAR(20),
    created_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    updated_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    CONSTRAINT pk_product_catalog PRIMARY KEY (product_id)
)
COMMENT = 'Raw product catalog data';
