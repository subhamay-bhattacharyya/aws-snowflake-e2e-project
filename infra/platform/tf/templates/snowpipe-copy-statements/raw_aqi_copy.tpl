COPY INTO ${database}.${schema}.${table} (
  INDEX_RECORD_TS,
  JSON_DATA,
  RECORD_COUNT,
  JSON_VERSION,
  _STG_FILE_NAME,
  _STG_FILE_LOAD_TS,
  _STG_FILE_MD5,
  _COPY_DATA_TS
)
FROM (
  SELECT
    $1:index_record_ts::TIMESTAMP_NTZ,
    $1:json_data::VARIANT,
    $1:record_count::NUMBER,
    $1:json_version::VARCHAR,
    METADATA$FILENAME,
    METADATA$FILE_LAST_MODIFIED,
    METADATA$FILE_CONTENT_KEY,
    CURRENT_TIMESTAMP()
  FROM @${database}.${schema}.${stage}
)
FILE_FORMAT = (FORMAT_NAME = '${database}.${schema}.${file_format}')
