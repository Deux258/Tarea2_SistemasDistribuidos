-- filtrar_eventos.pig
-- Uso: pig -param INPUT_CSV=... -param OUTPUT_CSV=... -f filtrar_eventos.pig

input = LOAD '/input/waze_data.csv' USING PigStorage(',') AS (
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

filtrados = FILTER input BY reliability > 3 AND type IS NOT NULL AND city IS NOT NULL;

STORE filtrados INTO '/input/cleaned_records' USING PigStorage(','); 