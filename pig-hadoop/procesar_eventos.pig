-- Cargar JSON exportado por mongoexport
raw = LOAD '/data/eventos_waze.json'
    USING JsonLoader(
      'type:chararray, comuna:chararray, timestamp:long, street:chararray'
    );

-- 1) Limpieza: eliminar documentos sin tipo o comuna
limpios = FILTER raw BY type IS NOT NULL AND comuna IS NOT NULL;

-- 2) Normalización: cadenas a minúsculas y fecha ISO
normalized = FOREACH limpios GENERATE
    LOWER(type)        AS tipo_norm:chararray,
    LOWER(comuna)      AS comuna_norm:chararray,
    ToString(ToDate(timestamp,'UNIX')) AS fecha_iso:chararray,
    LOWER(street)      AS calle_norm:chararray;

-- 3) Agrupamiento por tipo y comuna
grp = GROUP normalized BY (tipo_norm, comuna_norm);

-- 4) Conteo de eventos por grupo
counts = FOREACH grp GENERATE
    group.tipo_norm  AS tipo,
    group.comuna_norm AS comuna,
    COUNT(normalized) AS total;

-- 5) Guardar resultados en CSV
STORE counts INTO '/data/resultados_tipo_comuna' USING PigStorage(',');
