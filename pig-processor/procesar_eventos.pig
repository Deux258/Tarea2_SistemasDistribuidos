-- ===================================================================
-- procesar_eventos.pig
-- Pipeline Apache Pig para: preprocesamiento, clasificación y análisis
-- de incidentes Waze por comuna, tipo y evolución temporal.
-- ===================================================================

-- 1) REGISTRAR CUALQUIER JAR NECESARIO (JsonLoader, expresiones de fecha, etc.)
-- -------------------------------------------------------------------
-- Si Pig está corriendo en un contenedor con la librería piggybank.jar, 
-- y JsonLoader está disponible, no hace falta registrar nada extra.
-- Si necesitas funciones avanzadas (DateTime), asegúrate de registrar piggybank:
-- REGISTER /path/to/piggybank.jar;

-- 2) LECTURA DE DATOS (JsonLoader)
-- -------------------------------------------------------------------
-- Asumimos que `eventos_waze.json` ya existe en HDFS o en el sistema de archivos local 
-- del nodo donde se ejecuta Pig. Su esquema se define a continuación.
filtered = LOAD '/data/eventos_filtrados/part*' 
    USING PigStorage(',') AS (
        type:chararray,
        city:chararray,
        timestamp:long,
        street:chararray,
        severity:int,
        reliability:int
    );

-- 1) PREPROCESAMIENTO DE DATOS
-- -------------------------------------------------------------------
-- 1.1) LIMPIEZA: eliminar registros incompletos o erróneos
--   - Filtrar cuando falte `type` o `city` (son campos críticos para el análisis)
--   - Podrías también filtrar si `timestamp` es nulo (later)

limpios = FILTER raw BY (type IS NOT NULL) AND (city IS NOT NULL) AND (timestamp IS NOT NULL);

-- 1.2) NORMALIZACIÓN Y TRANSFORMACIÓN:
--   - Convertir `type` y `city` a minúsculas para agrupar de forma consistente.
--   - Crear un campo `fecha_iso` (YYYY-MM-DD) a partir de `timestamp`.
--   - Crear un campo `hora` (HH) para análisis de “horas pico”.
--   - En este ejemplo, usamos las *Funciones de Fecha* de Pig: ToDate, GetYear, GetMonth, GetDay, GetHour.
--   - Para convertir milisegundos a “DateTime” usamos ToDate(timestamp, 'milliseconds')

normalized = FOREACH limpios GENERATE
    LOWER(type)             AS tipo_norm:chararray,
    LOWER(city)             AS comuna_norm:chararray,
    ToDate(timestamp, 'milliseconds') AS datetime:datetime,
    LOWER(street)           AS calle_norm:chararray;

-- 1.2.1) De la fecha completa (`datetime`) se extrae campo `fecha_iso`

fecha_unificada = FOREACH normalized GENERATE
    tipo_norm            AS tipo_norm:chararray,
    comuna_norm          AS comuna_norm:chararray,
    ToString(GetYear(datetime))             +'-' 
      + RIGHT('00' + ToString(GetMonth(datetime)), 2)  + '-' 
      + RIGHT('00' + ToString(GetDay(datetime)), 2)    AS fecha_iso:chararray,
    ToString(GetHour(datetime))               AS hora_str:chararray,
    datetime                                                 AS datetime:datetime;

-- 1.3) RESULTADO del preprocesamiento:
--     (tipo_norm, comuna_norm, fecha_iso, hora_str, datetime)

preproceso_final = FOREACH fecha_unificada GENERATE 
    tipo_norm     AS tipo:chararray,
    comuna_norm   AS comuna:chararray,
    fecha_iso:chararray,
    hora_str:chararray,
    datetime:datetime;

-- 2) CLASIFICACIÓN Y ESTRUCTURACIÓN
-- -------------------------------------------------------------------
-- Agrupamos la data según los criterios relevantes:
--    2.1) Agrupar por tipo de incidente para ver su frecuencia global.
--    2.2) Agrupar por comuna para ver patrones geográficos.
--    2.3) Agrupar por (tipo, comuna) para ver con detalle la distribución.
--    2.4) Agrupar por fecha (dia a dia) para tendencias temporales.
--    2.5) Agrupar por hora para ver “horas pico” de incidentes.
--
-- A) Agrupamiento por TIPO (solo tipo):

grp_por_tipo = GROUP preproceso_final BY tipo;
conteo_por_tipo = FOREACH grp_por_tipo GENERATE 
    group            AS tipo_incidente:chararray,
    COUNT(preproceso_final) AS total_por_tipo:long;
--         => Tupla: (tipo_incidente, total_por_tipo)

-- B) Agrupamiento por COMUNA (solo comuna):

grp_por_comuna = GROUP preproceso_final BY comuna;
conteo_por_comuna = FOREACH grp_por_comuna GENERATE 
    group            AS comuna_nombre:chararray,
    COUNT(preproceso_final) AS total_por_comuna:long;
--         => Tupla: (comuna_nombre, total_por_comuna)

-- C) Agrupamiento combinado (TIPO + COMUNA):

grp_tipo_comuna = GROUP preproceso_final BY (tipo, comuna);
conteo_tipo_comuna = FOREACH grp_tipo_comuna GENERATE
    group.tipo       AS tipo_incidente:chararray,
    group.comuna     AS comuna_nombre:chararray,
    COUNT(preproceso_final)   AS total_tipo_comuna:long;
--         => Tupla: (tipo_incidente, comuna_nombre, total_tipo_comuna)

-- 3) ANÁLISIS EXPLORATORIO: EVOLUCIÓN TEMPORAL
-- -------------------------------------------------------------------
-- 3.1) Agrupar por FECHA (dia a dia) para identificar picos diarios

grp_por_fecha = GROUP preproceso_final BY fecha_iso;
conteo_por_fecha = FOREACH grp_por_fecha GENERATE
    group                AS fecha_dia:chararray,
    COUNT(preproceso_final) AS total_por_dia:long;
--         => Tupla: (fecha_dia, total_por_dia)

-- 3.2) Agrupar por HORA (hora del día, 0–23) para ver picos horarios

grp_por_hora = GROUP preproceso_final BY hora_str;
conteo_por_hora = FOREACH grp_por_hora GENERATE
    group                AS hora:chararray,
    COUNT(preproceso_final) AS total_por_hora:long;
--         => Tupla: (hora, total_por_hora)

-- 3.3) Agrupar “TIPO + FECHA” para ver tendencias de cada tipo de incidente día a día

grp_tipo_fecha = GROUP preproceso_final BY (tipo, fecha_iso);
conteo_tipo_fecha = FOREACH grp_tipo_fecha GENERATE
    group.tipo       AS tipo_incidente:chararray,
    group.fecha_iso  AS fecha_dia:chararray,
    COUNT(preproceso_final)    AS total_tipo_por_dia:long;
--         => Tupla: (tipo_incidente, fecha_dia, total_tipo_por_dia)

-- 3.4) Agrupar “COMUNA + FECHA” para ver la evolución geográfica en el tiempo

grp_comuna_fecha = GROUP preproceso_final BY (comuna, fecha_iso);
conteo_comuna_fecha = FOREACH grp_comuna_fecha GENERATE
    group.comuna     AS comuna_nombre:chararray,
    group.fecha_iso  AS fecha_dia:chararray,
    COUNT(preproceso_final)    AS total_comuna_por_dia:long;
--         => Tupla: (comuna_nombre, fecha_dia, total_comuna_por_dia)

-- 4) SALIDA DE RESULTADOS
-- -------------------------------------------------------------------
-- Decidimos exportar cada conjunto a un CSV separado dentro de HDFS (o local) para su posterior uso:
STORE conteo_por_tipo        INTO 'resultado_tipo'        USING PigStorage(',');
STORE conteo_por_comuna      INTO 'resultado_comuna'      USING PigStorage(',');
STORE conteo_tipo_comuna     INTO 'resultado_tipo_comuna' USING PigStorage(',');
STORE conteo_por_fecha       INTO 'resultado_fecha'       USING PigStorage(',');
STORE conteo_por_hora        INTO 'resultado_hora'        USING PigStorage(',');
STORE conteo_tipo_fecha      INTO 'resultado_tipo_fecha'  USING PigStorage(',');
STORE conteo_comuna_fecha    INTO 'resultado_comuna_fecha' USING PigStorage(',');

-- FIN del script