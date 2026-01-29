# -- infra/snowflake/tf/modules/database/main.tf (Child Module)
# ============================================================================
# Snowflake Database Sub-Module
# ============================================================================

resource "snowflake_database" "this" {
  for_each = { for db in var.databases : db.name => db }

  name    = each.value.name
  comment = each.value.comment
}

resource "snowflake_schema" "schemas" {
  for_each = merge([
    for db_key, db in { for db in var.databases : db.name => db } : {
      for schema in lookup(db, "schemas", []) : "${db.name}.${schema.name}" => {
        database = db.name
        name     = schema.name
        comment  = lookup(schema, "comment", "")
      }
    }
  ]...)

  database = snowflake_database.this[each.value.database].name
  name     = each.value.name
  comment  = each.value.comment

  depends_on = [snowflake_database.this]
}
