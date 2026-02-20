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

  # Check if storage integrations are configured (known at plan time from input config)
  has_storage_integration_config = length(lookup(local.snowflake_config, "storage_integrations", {})) > 0

  # Assume role policy - uses Snowflake principal ARN and external ID from trust config JSON
  # On first apply, these are empty so we use a placeholder
  # After storage integration is created, update the JSON config with actual values
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
    bucket_policy = templatefile("${path.module}/templates/bucket-policy/s3-bucket-policy.tpl", {
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
            usage_roles                = [var.data_object_provisioner_role, var.ingest_object_provisioner_role]
            create_file_format_roles   = [var.data_object_provisioner_role]
            create_stage_roles         = [var.ingest_object_provisioner_role]
            create_table_roles         = [var.data_object_provisioner_role]
            create_pipe_roles          = [var.ingest_object_provisioner_role]
            create_dynamic_table_roles = [var.data_object_provisioner_role]
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
              # Grants - INGEST_ADMIN needs USAGE to use file formats in pipes
              usage_roles = [var.ingest_object_provisioner_role]
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
      # Grants - USAGE privilege needed by roles that use the storage integration
      grants = [
        { role_name = var.ingest_object_provisioner_role, privileges = ["USAGE"] },
        { role_name = var.data_object_provisioner_role, privileges = ["USAGE"] },
        { role_name = var.db_provisioner_role, privileges = ["USAGE"] }
      ]
    }
  }

  # Stages - flatten from all databases/schemas into a map
  # All stage objects have the same structure (null for non-applicable attributes)
  stages = {
    for item in flatten([
      for db_key, db in lookup(local.snowflake_config, "databases", {}) : [
        for schema in lookup(db, "schemas", []) : [
          for stage_key, stage in lookup(schema, "stages", {}) : {
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
            # Grants - READ privilege for external stages, READ/WRITE for internal stages
            grants = lookup(stage, "stage_type", "internal") == "external" ? [
              { role_name = var.ingest_object_provisioner_role, privileges = ["READ"] },
              { role_name = var.data_object_provisioner_role, privileges = ["READ"] },
              { role_name = var.db_provisioner_role, privileges = ["READ"] }
              ] : [
              { role_name = var.ingest_object_provisioner_role, privileges = ["READ", "WRITE"] },
              { role_name = var.data_object_provisioner_role, privileges = ["READ", "WRITE"] },
              { role_name = var.db_provisioner_role, privileges = ["READ", "WRITE"] }
            ]
            # Internal stage attributes (null for external)
            directory_enabled = lookup(stage, "stage_type", "internal") == "internal" ? lookup(stage, "directory_enabled", false) : null
            # External stage attributes (null for internal)
            url = lookup(stage, "stage_type", "internal") == "external" ? (
              lookup(stage, "url", null) != null ? replace(stage.url, "the-s3-bucket", local.s3_config.bucket_name) : "s3://${local.s3_config.bucket_name}/"
            ) : null
            storage_integration = lookup(stage, "stage_type", "internal") == "external" ? (
              lookup(stage, "storage_integration", null) != null && lookup(stage, "storage_integration", "") != "" ? (var.project_code != "" ? upper("${var.project_code}_${stage.storage_integration}") : stage.storage_integration) : (var.project_code != "" ? upper("${var.project_code}_S3_STORAGE_INTEGRATION") : "S3_STORAGE_INTEGRATION")
            ) : null
          }
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
            key        = "${db_key}_${lower(schema.name)}_${table_key}"
            database   = var.project_code != "" ? upper("${var.project_code}_${db.name}") : db.name
            schema     = schema.name
            name       = table.name
            table_type = lookup(table, "table_type", "PERMANENT")
            comment    = lookup(table, "comment", "")
            columns = [
              for col in table.columns : {
                name     = col.name
                type     = col.type
                nullable = lookup(col, "nullable", true)
                default  = lookup(col, "default", null)
                comment  = lookup(col, "comment", null)
                autoincrement = lookup(col, "autoincrement", null) != null ? {
                  start     = lookup(col.autoincrement, "start", 1)
                  increment = lookup(col.autoincrement, "increment", 1)
                  order     = lookup(col.autoincrement, "order", false)
                } : null
              }
            ]
            primary_key                 = lookup(table, "primary_key", null)
            cluster_by                  = lookup(table, "cluster_by", null)
            data_retention_time_in_days = lookup(table, "data_retention_time_in_days", 1)
            change_tracking             = lookup(table, "change_tracking", false)
            drop_before_create          = lookup(table, "drop_before_create", false)
            # Grants - INGEST_ADMIN needs INSERT and SELECT for snowpipe operations
            grants = [
              { role_name = var.ingest_object_provisioner_role, privileges = ["INSERT", "SELECT"] }
            ]
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
            # Generate copy_statement from template if copy_template is provided
            copy_statement = lookup(pipe, "copy_template", null) != null ? templatefile(
              "${path.module}/templates/snowpipe-copy-statements/${pipe.copy_template}",
              {
                database    = var.project_code != "" ? upper("${var.project_code}_${db.name}") : db.name
                schema      = schema.name
                table       = lookup(pipe, "table", "")
                stage       = lookup(pipe, "stage", "")
                file_format = lookup(pipe, "file_format", "")
              }
            ) : (var.project_code != "" ? replace(pipe.copy_statement, db.name, upper("${var.project_code}_${db.name}")) : pipe.copy_statement)
            auto_ingest = lookup(pipe, "auto_ingest", false)
            # aws_sns_topic_arn is optional - only needed if using SNS
            aws_sns_topic_arn = lookup(pipe, "aws_sns_topic_arn", null)
            comment           = lookup(pipe, "comment", "")
          }
        ]
      ]
    ]) : item.key => item
  }

  # Dynamic Tables - flatten from all databases/schemas into a map
  dynamic_tables = {
    for item in flatten([
      for db_key, db in lookup(local.snowflake_config, "databases", {}) : [
        for schema in lookup(db, "schemas", []) : [
          for dt_key, dt in lookup(schema, "dynamic_tables", {}) : {
            key      = "${db_key}_${lower(schema.name)}_${dt_key}"
            name     = var.project_code != "" ? upper("${var.project_code}_${dt.name}") : dt.name
            database = var.project_code != "" ? upper("${var.project_code}_${db.name}") : db.name
            schema   = schema.name
            warehouse = lookup(dt, "warehouse", null) != null ? (
              var.project_code != "" ? upper("${var.project_code}_${dt.warehouse}") : upper(dt.warehouse)
            ) : null
            # Source table info for grants
            source_schema = lookup(dt, "source_schema", null)
            source_table  = lookup(dt, "source_table", null)
            # Generate query from template if query_template_file is provided
            query = lookup(dt, "query_template_file", null) != null ? templatefile(
              "${path.module}/templates/dynamic-tables/${dt.query_template_file}",
              {
                database      = var.project_code != "" ? upper("${var.project_code}_${db.name}") : db.name
                schema        = schema.name
                source_schema = lookup(dt, "source_schema", "BRONZE")
                table         = lookup(dt, "source_table", "RAW_AQI")
              }
            ) : lookup(dt, "query", null)
            target_lag   = lookup(dt, "target_lag", "1 hour")
            refresh_mode = lookup(dt, "refresh_mode", null)
            comment      = lookup(dt, "comment", "")
          }
        ]
      ]
    ]) : item.key => item
  }
}
