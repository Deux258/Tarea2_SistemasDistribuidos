-- ===================================================================
-- filtrar_eventos.pig
-- Script para filtrar eventos Waze según criterios específicos
-- ===================================================================

-- Cargar datos desde el archivo JSON exportado de MongoDB
eventos = LOAD '/data/eventos_waze.json' 
    USING JsonLoader(
      'type:chararray,           -- tipo de incidente
       city:chararray,           -- comuna o ciudad
       timestamp:long,           -- marca de tiempo
       street:chararray,         -- calle o ruta
       severity:int,             -- severidad del incidente
       reliability:int'          -- confiabilidad del reporte
    );

FLATTEN(eventos) AS (type, city, timestamp, street);
-- Filtrar eventos según criterios:
-- 1. Severidad > 2 (incidentes importantes)
-- 2. Confiabilidad > 3 (reportes confiables)
-- 3. Campos críticos no nulos
filtrados = FILTER eventos BY 
    severity > 2 AND 
    reliability > 3 AND 
    type IS NOT NULL AND 
    city IS NOT NULL AND 
    timestamp IS NOT NULL;

-- Guardar resultados filtrados
STORE filtrados INTO '/data/eventos_filtrados' USING PigStorage(',');