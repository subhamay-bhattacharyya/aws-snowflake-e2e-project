# -- infra/platform/tf/locals.tf (Platform Module)
# ============================================================================
# Local Values
# ============================================================================

# data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# Compute KMS key alias first (no dependency on s3_config)
locals {
  kms_key_alias_raw = try(jsondecode(file("${path.module}/${var.aws_config_path}")).aws.s3.kms_key_alias, null)
  kms_key_alias     = local.kms_key_alias_raw != null ? (startswith(local.kms_key_alias_raw, "alias/") ? local.kms_key_alias_raw : "alias/${local.kms_key_alias_raw}") : null
}

data "aws_kms_key" "kms" {
  count  = local.kms_key_alias != null ? 1 : 0
  key_id = local.kms_key_alias
}

locals {
  # current_region = data.aws_region.current.id

  # Parse config from JSON files (relative to module path)
  aws_config_file       = jsondecode(file("${path.module}/${var.aws_config_path}"))
  snowflake_config_file = jsondecode(file("${path.module}/${var.snowflake_config_path}"))

  # Extract nested sections
  aws_config       = local.aws_config_file.aws
  snowflake_config = local.snowflake_config_file
  trust_config     = local.aws_config_file.trust

  # ============================================================================
  # AWS Configuration
  # ============================================================================

  # Assume role policy - uses Snowflake principal ARN and external ID from trust config
  snowflake_principal_arn = local.trust_config.snowflake_principal_arn
  snowflake_external_id   = local.trust_config.snowflake_external_id
  has_snowflake_trust     = local.snowflake_principal_arn != "" && local.snowflake_external_id != ""

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { AWS = local.has_snowflake_trust ? local.snowflake_principal_arn : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" },
      Action    = "sts:AssumeRole",
      Condition = local.has_snowflake_trust ? {
        StringEquals = {
          "sts:ExternalId" = local.snowflake_external_id
        }
      } : {}
    }]
  })

  # S3 Configuration
  s3_config = {
    bucket_name   = "${var.project_code}-${local.aws_config.s3.bucket_name}-${var.environment}-${local.aws_config.region}"
    versioning    = local.aws_config.s3.versioning == true ? true : false
    kms_key_alias = local.kms_key_alias != null ? replace(local.kms_key_alias, "alias/", "") : null
    sse_algorithm = local.kms_key_alias != null ? "aws:kms" : null
    bucket_keys   = try(local.aws_config.s3.bucket_keys, null)
    bucket_policy = templatefile("${path.module}/../../aws/tf/templates/bucket-policy/s3-bucket-policy.tpl", {
      aws_account_id = data.aws_caller_identity.current.account_id
      bucket_name    = "${var.project_code}-${local.aws_config.s3.bucket_name}-${var.environment}-${local.aws_config.region}"
    })
  }

  # IAM Role Configuration
  iam_role_config = {
    name               = "${var.project_code}-${local.aws_config.iam.role_name}-${var.environment}"
    assume_role_policy = local.assume_role_policy
    s3_bucket_arn      = "arn:aws:s3:::${local.s3_config.bucket_name}"
    kms_key_arn        = local.kms_key_alias != null ? data.aws_kms_key.kms[0].arn : null
    inline_policies = [
      for policy in local.aws_config.iam.policies : {
        name = policy.name
        policy = jsonencode({
          Version = "2012-10-17"
          Statement = [{
            Sid    = policy.sid
            Effect = policy.effect
            Action = policy.action
            Resource = (
              policy.resource == "s3-bucket-arn" ? "arn:aws:s3:::${local.s3_config.bucket_name}" :
              policy.resource == "s3-bucket-arn/*" ? "arn:aws:s3:::${local.s3_config.bucket_name}/*" :
              policy.resource == "kms-key-arn" ? (local.kms_key_alias != null ? data.aws_kms_key.kms[0].arn : "*") :
              policy.resource
            )
          }]
        })
      }
    ]
  }

  # ============================================================================
  # Snowflake Configuration
  # ============================================================================

  # Warehouses - add optional prefix to names
  warehouses = {
    for key, wh in lookup(local.snowflake_config, "warehouses", {}) : key => merge(wh, {
      name = var.project_code != "" ? upper("${var.project_code}_${wh.name}") : wh.name
    })
  }

  # Databases with schemas - nested structure
  database_schemas = {
    for db_key, db in lookup(local.snowflake_config, "databases", {}) : db_key => {
      name    = var.project_code != "" ? upper("${var.project_code}_${db.name}") : db.name
      comment = lookup(db, "comment", "")
      grants = {
        usage_roles = [
          var.data_object_provisioner_role,
          var.ingest_object_provisioner_role
        ]
      }
      schemas = [
        for schema in lookup(db, "schemas", []) : {
          name    = schema.name
          comment = lookup(schema, "comment", "")
          grants = {
            usage_roles              = [var.data_object_provisioner_role, var.ingest_object_provisioner_role]
            create_file_format_roles = [var.data_object_provisioner_role]
            create_stage_roles       = [var.ingest_object_provisioner_role]
            create_table_roles       = [var.data_object_provisioner_role]
            create_pipe_roles        = [var.ingest_object_provisioner_role]
          }
        }
      ]
    }
  }

  # File Formats - flatten from all databases/schemas into a map with normalized structure
  # Only pass attributes that are explicitly set in config, let module defaults handle the rest
  file_formats = {
    for item in flatten([
      for db_key, db in lookup(local.snowflake_config, "databases", {}) : [
        for schema in lookup(db, "schemas", []) : [
          for ff_key, ff in lookup(schema, "file_formats", {}) : merge(
            {
              name        = ff.name
              format_type = ff.type
              database    = var.project_code != "" ? upper("${var.project_code}_${db.name}") : db.name
              schema      = schema.name
            },
            # Only include optional attributes if they are explicitly defined in config
            lookup(ff, "comment", null) != null ? { comment = ff.comment } : {},
            lookup(ff, "compression", null) != null ? { compression = ff.compression } : {},
            # CSV options
            lookup(ff, "field_delimiter", null) != null ? { field_delimiter = ff.field_delimiter } : {},
            lookup(ff, "record_delimiter", null) != null ? { record_delimiter = ff.record_delimiter } : {},
            lookup(ff, "skip_header", null) != null ? { skip_header = ff.skip_header } : {},
            lookup(ff, "field_optionally_enclosed_by", null) != null ? { field_optionally_enclosed_by = ff.field_optionally_enclosed_by } : {},
            lookup(ff, "trim_space", null) != null ? { trim_space = ff.trim_space } : {},
            lookup(ff, "error_on_column_count_mismatch", null) != null ? { error_on_column_count_mismatch = ff.error_on_column_count_mismatch } : {},
            lookup(ff, "escape", null) != null ? { escape = ff.escape } : {},
            lookup(ff, "escape_unenclosed_field", null) != null ? { escape_unenclosed_field = ff.escape_unenclosed_field } : {},
            lookup(ff, "date_format", null) != null ? { date_format = ff.date_format } : {},
            lookup(ff, "timestamp_format", null) != null ? { timestamp_format = ff.timestamp_format } : {},
            lookup(ff, "null_if", null) != null ? { null_if = ff.null_if } : {},
            # JSON options
            lookup(ff, "enable_octal", null) != null ? { enable_octal = ff.enable_octal } : {},
            lookup(ff, "allow_duplicate", null) != null ? { allow_duplicate = ff.allow_duplicate } : {},
            lookup(ff, "strip_outer_array", null) != null ? { strip_outer_array = ff.strip_outer_array } : {},
            lookup(ff, "strip_null_values", null) != null ? { strip_null_values = ff.strip_null_values } : {},
            lookup(ff, "ignore_utf8_errors", null) != null ? { ignore_utf8_errors = ff.ignore_utf8_errors } : {},
          )
        ]
      ]
    ]) : item.name => item
  }

  # Storage Integrations - read from top level (account-level object)
  storage_integrations = {
    for si_key, si in lookup(local.snowflake_config, "storage_integrations", {}) : si_key => {
      name                      = var.project_code != "" ? upper("${var.project_code}_${si.name}") : si.name
      storage_provider          = si.storage_provider
      storage_aws_role_arn      = local.iam_role_config.name != "" ? "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.iam_role_config.name}" : lookup(si, "storage_aws_role_arn", "")
      storage_allowed_locations = [for loc in lookup(si, "storage_allowed_locations", []) : "s3://${local.s3_config.bucket_name}/${loc}"]
      storage_blocked_locations = lookup(si, "storage_blocked_locations", [])
      enabled                   = lookup(si, "enabled", true)
      comment                   = lookup(si, "comment", "")
    }
  }

  # Stages - flatten from all databases/schemas into a map
  # Structure differs based on stage_type (internal vs external)
  stages = {
    for item in flatten([
      for db_key, db in lookup(local.snowflake_config, "databases", {}) : [
        for schema in lookup(db, "schemas", []) : [
          for stage_key, stage in lookup(schema, "stages", {}) : merge(
            {
              name       = stage.name
              database   = var.project_code != "" ? upper("${var.project_code}_${db.name}") : db.name
              schema     = schema.name
              stage_type = lookup(stage, "stage_type", "internal")
              comment    = lookup(stage, "comment", "")
              file_format = lookup(stage, "file_format", null) != null ? (
                upper(lookup(stage, "file_format", "")) == "JSON" ? "JSON_FILE_FORMAT" :
                upper(lookup(stage, "file_format", "")) == "CSV" ? "CSV_FILE_FORMAT" :
                lookup(stage, "file_format", null)
              ) : null
            },
            # Add internal stage specific attributes
            lookup(stage, "stage_type", "internal") == "internal" ? {
              directory_enabled = lookup(stage, "directory_enabled", false)
            } : {},
            # Add external stage specific attributes only if stage_type is external
            lookup(stage, "stage_type", "internal") == "external" ? {
              url                 = lookup(stage, "url", null) != null ? replace(stage.url, "the-s3-bucket", local.s3_config.bucket_name) : "s3://${local.s3_config.bucket_name}/"
              storage_integration = lookup(stage, "storage_integration", null) != null && lookup(stage, "storage_integration", "") != "" ? (var.project_code != "" ? upper("${var.project_code}_${stage.storage_integration}") : stage.storage_integration) : (var.project_code != "" ? upper("${var.project_code}_S3_STORAGE_INTEGRATION") : "S3_STORAGE_INTEGRATION")
            } : {}
          )
        ]
      ]
    ]) : item.name => item
  }

  # Tables - flatten from all databases/schemas into a map
  tables = {
    for item in flatten([
      for db_key, db in lookup(local.snowflake_config, "databases", {}) : [
        for schema in lookup(db, "schemas", []) : [
          for table_key, table in lookup(schema, "tables", {}) : {
            key      = "${db_key}_${lower(schema.name)}_${table_key}"
            name     = table.name
            database = var.project_code != "" ? upper("${var.project_code}_${db.name}") : db.name
            schema   = schema.name
            columns  = table.columns
            comment  = lookup(table, "comment", "")
          }
        ]
      ]
    ]) : item.key => item
  }

  # Snowpipes - flatten from all databases/schemas into a map
  snowpipes = {
    for item in flatten([
      for db_key, db in lookup(local.snowflake_config, "databases", {}) : [
        for schema in lookup(db, "schemas", []) : [
          for pipe_key, pipe in lookup(schema, "snowpipes", {}) : {
            key      = "${db_key}_${lower(schema.name)}_${pipe_key}"
            name     = var.project_code != "" ? upper("${var.project_code}_${pipe.name}") : pipe.name
            database = var.project_code != "" ? upper("${var.project_code}_${db.name}") : db.name
            schema   = schema.name
            # Replace database/schema references in copy_statement with prefixed names
            copy_statement = var.project_code != "" ? replace(pipe.copy_statement, db.name, upper("${var.project_code}_${db.name}")) : pipe.copy_statement
            auto_ingest    = lookup(pipe, "auto_ingest", true)
            comment        = lookup(pipe, "comment", "")
          }
        ]
      ]
    ]) : item.key => item
  }
}
