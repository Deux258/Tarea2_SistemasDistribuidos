-- ===================================================================
-- filtrar_eventos.pig
-- Filtrado y normalización de eventos Waze desde CSV
-- ===================================================================

raw_data = LOAD '/data/eventos_waze.csv'
    USING PigStorage(',')
    AS (
        uuid:chararray,
        type:chararray,
        city:chararray,
        street:chararray,
        speed:chararray,
        reliability:chararray,
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

-- 1. Eliminar duplicados exactos
deduped = DISTINCT raw_data;

-- 2. Filtrar registros válidos con campos clave presentes y no vacíos
clean_data = FILTER deduped BY 
    (uuid IS NOT NULL AND TRIM(uuid) != '' AND
     type IS NOT NULL AND TRIM(type) != '' AND
     city IS NOT NULL AND TRIM(city) != '' AND
     street IS NOT NULL AND TRIM(street) != '' AND
     pubMillis IS NOT NULL AND TRIM(pubMillis) != '');

-- 3. Normalización de campos clave y casting de pubMillis a long
homogenized = FOREACH clean_data GENERATE
    uuid,
    UPPER(TRIM(type)) AS type,
    UPPER(TRIM(city)) AS city,
    UPPER(TRIM(street)) AS street,
    (long)pubMillis AS timestamp,
    speed, reliability, confidence, country, reportRating, additionalInfo,
    fromNodeId, id, inscale, magvar, nComments, nThumbsUp, nearBy, provider,
    providerId, reportBy, reportByMunicipalityUser, reportDescription, reportMood,
    roadType, subtype, toNodeId;

-- 4. Guardar datos filtrados y normalizados
STORE homogenized INTO '/data/eventos_filtrados' USING PigStorage(',');