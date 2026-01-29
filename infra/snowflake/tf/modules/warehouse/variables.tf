# -- infra/snowflake/tf/modules/warehouse/variables.tf (Child Module)
# ============================================================================
# Snowflake Warehouse Variables
# ============================================================================

variable "warehouses" {
  description = "List of warehouse configurations as JSON objects"
  type = list(object({
    name                      = string
    warehouse_size            = optional(string, "X-SMALL")
    auto_suspend              = optional(number, 60)
    auto_resume               = optional(bool, true)
    warehouse_type            = optional(string, "STANDARD")
    comment                   = optional(string, "")
    enable_query_acceleration = optional(bool, false)
    min_cluster_count         = optional(number, 1)
    max_cluster_count         = optional(number, 1)
    scaling_policy            = optional(string, "STANDARD")
    initially_suspended       = optional(bool, true)
  }))
}
