# -- infra/snowflake/tf/modules/storage_integration/main.tf (Child Module)
# ============================================================================
# Snowflake Storage Integration Sub-Module
# ============================================================================

resource "snowflake_storage_integration" "this" {
  for_each = { for si in var.storage_integrations : si.name => si }

  name    = each.value.name
  type    = each.value.type
  enabled = lookup(each.value, "enabled", true)
  comment = lookup(each.value, "comment", "")

  # Storage provider configuration
  storage_provider        = each.value.storage_provider
  storage_aws_external_id = each.value.storage_aws_external_id

  # S3 specific
  storage_aws_role_arn = lookup(each.value, "storage_aws_role_arn", null)

  # Azure specific
  azure_tenant_id = lookup(each.value, "azure_tenant_id", null)

  # GCS specific
  # GCS uses service account which is configured differently

  # Storage locations
  storage_allowed_locations = each.value.storage_allowed_locations
  storage_blocked_locations = lookup(each.value, "storage_blocked_locations", [])
}
