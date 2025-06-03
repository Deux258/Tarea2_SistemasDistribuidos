-- ===================================================================
-- filtrar_eventos.pig
-- Script para filtrar eventos Waze según criterios específicos
-- ===================================================================

-- Cargar datos desde el archivo JSON exportado de MongoDB
eventos = LOAD '/data-storage/eventos.json' 
    USING JsonLoader(
      'type:chararray,
       city:chararray,
       timestamp:long,
       street:chararray,
       severity:int,
       reliability:int'
    );

-- FLATTEN(eventos) AS (type, city, timestamp, street);
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
STORE filtrados INTO '/data-storage/eventos_filtrados' USING PigStorage(',');





REGISTER '/opt/pig/contrib/piggybank/java/piggybank.jar';

%default CSV_INPUT '/user/waze/incidentes_limpios.csv';

incidentes_raw = LOAD '$CSV_INPUT' USING PigStorage(',')
    AS (
        fecha:chararray,
        tipo:chararray,
        subtipo:chararray,
        subtipo_norm:chararray,
        ciudad:chararray,
        calle:chararray,
        lat:double,
        lon:double
    );

-- filtrar:
incidentes_filtrados = FILTER incidentes_raw BY
    fecha  IS NOT NULL
    AND ciudad  IS NOT NULL
    AND tipo    IS NOT NULL
    AND lat     IS NOT NULL
    AND lon     IS NOT NULL
    AND fecha != ''
    AND ciudad != ''
    AND tipo   != '';

-- homogeneizar:
incidentes_norm = FOREACH incidentes_filtrados GENERATE
    LOWER(TRIM(fecha))        AS fecha_norm:chararray,
    UPPER(TRIM(tipo))         AS tipo_norm:chararray,
    UPPER(TRIM(subtipo_norm)) AS subtipo_norm:chararray,
    LOWER(TRIM(ciudad))       AS ciudad_norm:chararray,
    calle                      AS calle:chararray,
    lat,
    lon;

-- pasar a fecha:
incidentes_final = FOREACH incidentes_norm GENERATE
    ToDate(fecha_norm, 'YYYY-MM-DD HH:mm:ss') AS fecha_dt:datetime,
    ciudad_norm AS ciudad:chararray,
    tipo_norm   AS tipo:chararray,
    subtipo_norm AS subtipo_norm:chararray,
    calle, lat, lon;

STORE incidentes_final
    INTO '/user/waze/output/incidentes_homogeneizados'
    USING PigStorage('\t');