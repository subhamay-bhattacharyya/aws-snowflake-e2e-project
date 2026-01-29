# -- infra/snowflake/tf/modules/storage_integration/outputs.tf (Child Module)
# ============================================================================
# Snowflake Storage Integration Outputs
# ============================================================================

output "storage_integrations" {
  description = "Map of storage integration names to their details"
  value = {
    for k, v in snowflake_storage_integration.this : k => {
      name                      = v.name
      id                        = v.id
      type                      = v.type
      storage_provider          = v.storage_provider
      storage_allowed_locations = v.storage_allowed_locations

      # AWS specific outputs
      storage_aws_iam_user_arn = try(v.storage_aws_iam_user_arn, null)
      storage_aws_external_id  = try(v.storage_aws_external_id, null)

      # Azure specific outputs
      azure_consent_url           = try(v.azure_consent_url, null)
      azure_multi_tenant_app_name = try(v.azure_multi_tenant_app_name, null)
    }
  }
}

output "storage_integration_names" {
  description = "List of storage integration names"
  value       = [for k, v in snowflake_storage_integration.this : v.name]
}
