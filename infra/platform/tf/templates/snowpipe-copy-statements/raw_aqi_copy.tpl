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
        TRY_TO_TIMESTAMP(t.$1:records[0].last_update::TEXT, 'dd-mm-yyyy hh24:mi:ss') AS INDEX_RECORD_TS,
        t.$1::VARIANT                                                                AS JSON_DATA,
        t.$1:total::INT                                                              AS RECORD_COUNT,
        t.$1:version::VARCHAR                                                        AS JSON_VERSION,
        METADATA$FILENAME                                                            AS _STG_FILE_NAME,
        METADATA$FILE_LAST_MODIFIED                                                  AS _STG_FILE_LOAD_TS,
        METADATA$FILE_CONTENT_KEY                                                    AS _STG_FILE_MD5,
        CURRENT_TIMESTAMP()                                                          AS _COPY_DATA_TS
    FROM @${database}.${schema}.${stage} t
)
FILE_FORMAT = (FORMAT_NAME = '${database}.${schema}.${file_format}')
