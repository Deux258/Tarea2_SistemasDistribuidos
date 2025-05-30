-- 1) Registrar los jars (no estrictamente necesario si están en $PIG_HOME/lib)
REGISTER $PIG_HOME/lib/mongo-hadoop-core-2.0.2.jar;
REGISTER $PIG_HOME/lib/mongo-hadoop-pig-2.0.2.jar;

-- 2) Definir el URI de MongoDB (user:pass, host y puerto)
DEFINE MongoLoader org.apache.pig.backend.hadoop.storage.MongoLoader(
    'mongodb://admin:pass@mongo:27017/waze_db.eventos'
);

-- 3) Cargar la colección 'eventos'
raw = LOAD 'mongo://waze_db.eventos' USING MongoLoader()
      AS (  country:chararray,
            inscale:chararray,
            city:chararray,
            reportRating:int,
            reportByMunicipalityUser:chararray,
            confidence:int,
            reliability:int,
            type:chararray,
            fromNodeId:long,
            uuid:chararray,
            speed:int,
            reportMood:int,
            roadType:int,
            magvar:int,
            subtype:chararray,
            street:chararray,
            additionalInfo:chararray,
            wazeData:chararray,
            toNodeId:long,
            location:map[],   -- si Pig puede mapear directamente a map
            id:chararray,
            pubMillis:long
      );

-- 1) Limpieza: eliminar documentos sin tipo o comuna
limpios = FILTER raw BY type IS NOT NULL AND comuna IS NOT NULL;

-- 2) Normalización: cadenas a minúsculas y fecha ISO
normalized = FOREACH limpios GENERATE
    LOWER(type)        AS tipo_norm:chararray,
    LOWER(comuna)      AS comuna_norm:chararray,
    ToString(ToDate(timestamp,'UNIX')) AS fecha_iso:chararray,
    LOWER(street)      AS calle_norm:chararray;

-- 3) Agrupamiento y conteo
grp = GROUP normalized BY (tipo_norm, comuna_norm);
counts = FOREACH grp GENERATE
    group.tipo_norm  AS tipo,
    group.comuna_norm AS comuna,
    COUNT(normalized) AS total;

-- 4) Mostrar resultados
DUMP counts;

-- 5) Guardar resultados en CSV
STORE counts INTO '/data/resultados_tipo_comuna' USING PigStorage(',');
