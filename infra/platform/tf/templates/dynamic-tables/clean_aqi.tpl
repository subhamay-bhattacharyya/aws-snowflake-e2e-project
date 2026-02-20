WITH air_quality_with_rank AS (
    SELECT 
        INDEX_RECORD_TS,
        JSON_DATA,
        RECORD_COUNT,
        JSON_VERSION,
        _STG_FILE_NAME,
        _STG_FILE_LOAD_TS,
        _STG_FILE_MD5,
        _COPY_DATA_TS,
        ROW_NUMBER() OVER (PARTITION BY INDEX_RECORD_TS ORDER BY _STG_FILE_LOAD_TS DESC) AS LATEST_FILE_RANK
    FROM ${database}.${source_schema}.${table}
    WHERE INDEX_RECORD_TS IS NOT NULL
),
unique_air_quality_data AS (
    SELECT 
        * 
    FROM 
        air_quality_with_rank 
    WHERE LATEST_FILE_RANK = 1
)
SELECT 
    INDEX_RECORD_TS,
    hourly_rec.value:country::TEXT                AS COUNTRY,
    hourly_rec.value:state::TEXT                  AS STATE,
    hourly_rec.value:city::TEXT                   AS CITY,
    hourly_rec.value:station::TEXT                AS STATION,
    hourly_rec.value:latitude::NUMBER(12,7)       AS LATITUDE,
    hourly_rec.value:longitude::NUMBER(12,7)      AS LONGITUDE,
    hourly_rec.value:pollutant_id::TEXT           AS POLLUTANT_ID,
    hourly_rec.value:pollutant_max::TEXT          AS POLLUTANT_MAX,
    hourly_rec.value:pollutant_min::TEXT          AS POLLUTANT_MIN,
    hourly_rec.value:pollutant_avg::TEXT          AS POLLUTANT_AVG,
    _STG_FILE_NAME                                AS _STG_FILE_NAME,
    _STG_FILE_LOAD_TS                             AS _STG_FILE_LOAD_TS,
    _STG_FILE_MD5                                 AS _STG_FILE_MD5,
    _COPY_DATA_TS                                 AS _COPY_DATA_TS
FROM 
    unique_air_quality_data,
    LATERAL FLATTEN (INPUT => JSON_DATA:records) hourly_rec
