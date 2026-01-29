-- ============================================================================
-- Streamlit Warehouse
-- Description: Warehouse for running Streamlit queries
-- ============================================================================

CREATE WAREHOUSE IF NOT EXISTS STREAMLIT_WH
  COMMENT = 'This warehouse will be used for running Streamlit queries.'
  WAREHOUSE_SIZE = 'x-small' 
  AUTO_RESUME = TRUE 
  AUTO_SUSPEND = 60 
  ENABLE_QUERY_ACCELERATION = FALSE 
  WAREHOUSE_TYPE = 'standard' 
  MIN_CLUSTER_COUNT = 1 
  MAX_CLUSTER_COUNT = 1 
  SCALING_POLICY = 'standard'
  INITIALLY_SUSPENDED = TRUE;
