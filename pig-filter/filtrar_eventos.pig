-- ===================================================================
-- filtrar_eventos.pig
-- Limpieza y normalización avanzada de eventos Waze desde CSV
-- ===================================================================

-- Uso: pig -x local -param INPUT_CSV=... -param OUTPUT_CSV=... filtrar_eventos.pig

input = LOAD '$INPUT_CSV' USING PigStorage(',') AS (
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

deduped = DISTINCT input;

clean_data = FILTER deduped BY 
    (uuid IS NOT NULL AND TRIM(uuid) != '' AND
     type IS NOT NULL AND TRIM(type) != '' AND
     city IS NOT NULL AND TRIM(city) != '' AND
     street IS NOT NULL AND TRIM(street) != '' AND
     pubMillis IS NOT NULL AND TRIM(pubMillis) != '');

normalized = FOREACH clean_data GENERATE
    uuid,
    UPPER(TRIM(type)) AS type,
    UPPER(TRIM(city)) AS city,
    UPPER(TRIM(street)) AS street,
    (long)pubMillis AS pubMillis;

STORE normalized INTO '$OUTPUT_CSV' USING PigStorage(',');