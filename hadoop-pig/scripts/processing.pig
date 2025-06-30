-- processing.pig

-- 1) Cargar registros limpios con el esquema completo desde HDFS
records_full = LOAD '/input/cleaned_records'
    USING PigStorage(',')
    AS (
        uuid:chararray,
        type:chararray,
        city:chararray,
        street:chararray,
        speed:chararray,
        reliability:int,
        confidence:chararray,
        country:chararray,
        reportRating:chararray,
        pubMillis:chararray,
        additionalInfo:chararray,
        fromNodeId:chararray,
        id:chararray,
        inscale:chararray,
        magvar:chararray,
        nComments:chararray,
        nThumbsUp:chararray,
        nearBy:chararray,
        provider:chararray,
        providerId:chararray,
        reportBy:chararray,
        reportByMunicipalityUser:chararray,
        reportDescription:chararray,
        reportMood:chararray,
        roadType:chararray,
        subtype:chararray,
        toNodeId:chararray
    );

-- 2) Seleccionar solo las columnas necesarias para las métricas
records = FOREACH records_full GENERATE type, city, street, (long)pubMillis AS timestamp;

-- 3) Incidentes por comuna
by_city = GROUP records BY city;
city_metrics = FOREACH by_city GENERATE group AS city, COUNT(records) AS total_incidents;
STORE city_metrics
    INTO 'file:/output/analysis_by_city'
    USING PigStorage(',');
DUMP city_metrics;

-- 4) Incidentes por tipo
by_type = GROUP records BY type;
type_metrics = FOREACH by_type GENERATE group AS type, COUNT(records) AS total_incidents;
STORE type_metrics
    INTO 'file:/output/analysis_by_type'
    USING PigStorage(',');
DUMP type_metrics;

-- 5) Incidentes por tipo y comuna
by_type_city = GROUP records BY (type, city);
type_city_metrics = FOREACH by_type_city GENERATE FLATTEN(group) AS (type, city), COUNT(records) AS total_incidents;
STORE type_city_metrics
    INTO 'file:/output/analysis_by_type_city'
    USING PigStorage(',');
DUMP type_city_metrics;

-- 6) Incidentes por calle y comuna
by_street_city = GROUP records BY (street, city);
street_city_metrics = FOREACH by_street_city GENERATE FLATTEN(group) AS (street, city), COUNT(records) AS total_incidents;
STORE street_city_metrics
    INTO 'file:/output/analysis_by_street_city'
    USING PigStorage(',');
DUMP street_city_metrics;

-- 7) Incidentes por día (epoch)
by_day = FOREACH records GENERATE (long)(timestamp / 86400000) AS day_epoch;
group_by_day = GROUP by_day BY day_epoch;
day_metrics = FOREACH group_by_day GENERATE group AS day_epoch, COUNT(by_day) AS total_incidents;
STORE day_metrics
    INTO 'file:/output/analysis_by_day'
    USING PigStorage(',');
DUMP day_metrics;
