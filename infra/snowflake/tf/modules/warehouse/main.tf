# -- infra/snowflake/tf/modules/warehouse/main.tf (Child Module)
# ============================================================================
# Snowflake Warehouse Sub-Module
# ============================================================================

resource "snowflake_warehouse" "this" {
  for_each = { for wh in var.warehouses : wh.name => wh }

  name                      = each.value.name
  warehouse_size            = each.value.warehouse_size
  auto_suspend              = each.value.auto_suspend
  auto_resume               = each.value.auto_resume
  warehouse_type            = each.value.warehouse_type
  comment                   = each.value.comment
  enable_query_acceleration = each.value.enable_query_acceleration
  min_cluster_count         = each.value.min_cluster_count
  max_cluster_count         = each.value.max_cluster_count
  scaling_policy            = each.value.scaling_policy
  initially_suspended       = each.value.initially_suspended
}
