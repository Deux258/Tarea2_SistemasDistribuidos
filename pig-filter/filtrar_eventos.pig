-- ===================================================================
-- filtrar_eventos.pig
-- Script para filtrar eventos Waze desde CSV
-- ===================================================================

eventos = LOAD '/data/eventos_waze.csv' 
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

filtrados = FILTER eventos BY 
    reliability > 3 AND 
    type IS NOT NULL AND 
    city IS NOT NULL;

STORE filtrados INTO '/data/eventos_filtrados' USING PigStorage(',');