# -- infra/snowflake/tf/modules/warehouse/outputs.tf (Child Module)
# ============================================================================
# Snowflake Warehouse Outputs
# ============================================================================

output "warehouses" {
  description = "Map of warehouse names to their details"
  value = {
    for k, v in snowflake_warehouse.this : k => {
      warehouse_type            = v.warehouse_type
      warehouse_size            = v.warehouse_size
      comment                   = v.comment
      auto_suspend              = v.auto_suspend
      initially_suspended       = v.initially_suspended
      enable_query_acceleration = v.enable_query_acceleration
      warehouse_type            = v.warehouse_type
      auto_resume               = v.auto_resume
      min_cluster_count         = v.min_cluster_count
      max_cluster_count         = v.max_cluster_count
    }
  }
}
