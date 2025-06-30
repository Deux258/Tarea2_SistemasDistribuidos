-- filtrar_eventos.pig
-- 1) Cargar datos
data = LOAD '/input/waze_data.csv'
    USING PigStorage(',')
    AS ( uuid:chararray, type:chararray, city:chararray, street:chararray,
         speed:chararray, reliability:int, confidence:chararray, country:chararray,
         reportRating:chararray, pubMillis:chararray, additionalInfo:chararray,
         fromNodeId:chararray, id:chararray, inscale:chararray, magvar:chararray,
         nComments:chararray, nThumbsUp:chararray, nearBy:chararray,
         provider:chararray, providerId:chararray, reportBy:chararray,
         reportByMunicipalityUser:chararray, reportDescription:chararray,
         reportMood:chararray, roadType:chararray, subtype:chararray,
         toNodeId:chararray );

-- 2) Filtrar calidad y campos no nulos
filtrados = FILTER data BY reliability > 3
                      AND type IS NOT NULL
                      AND city IS NOT NULL;

-- Limitar la impresión a los primeros 20 registros
filtrados_limit = LIMIT filtrados 20;
DUMP filtrados_limit;

-- 4) Guardar para la siguiente etapa (en local)
STORE filtrados
    INTO 'file:/output/cleaned_records'
    USING PigStorage(','); 