-- Cargar datos desde Elasticsearch
REGISTER /opt/pig/lib/elasticsearch-hadoop-8.8.1.jar;

-- Configurar el almacenamiento de Elasticsearch
SET es.nodes 'my-elasticsearch-project-f2727a.es.us-east-1.aws.elastic.cloud'
SET es.port '443'
SET es.nodes.wan.only 'true'
SET es.net.http.auth.api.key.id 'API_KEY_ID'
SET es.net.http.auth.api.key.secret 'API_KEY_SECRET'
SET es.net.ssl 'true'
SET es.net.ssl.cert.allow.self.signed 'true'

-- Cargar datos de Waze
waze_data = LOAD 'waze_events' USING org.elasticsearch.hadoop.pig.EsStorage();

-- Limpieza y normalización de datos
cleaned_data = FOREACH waze_data GENERATE
    -- Normalizar tipo de incidente
    CASE type
        WHEN 'ACCIDENT' THEN 'ACCIDENTE'
        WHEN 'JAM' THEN 'CONGESTION'
        WHEN 'ROAD_CLOSED' THEN 'CORTE'
        WHEN 'HAZARD' THEN 'PELIGRO'
        ELSE type
    END as tipo_incidente,
    
    -- Normalizar subtipo
    CASE subtype
        WHEN 'ACCIDENT_MAJOR' THEN 'ACCIDENTE_GRAVE'
        WHEN 'ACCIDENT_MINOR' THEN 'ACCIDENTE_LEVE'
        WHEN 'JAM_HEAVY_TRAFFIC' THEN 'CONGESTION_GRAVE'
        WHEN 'JAM_MODERATE_TRAFFIC' THEN 'CONGESTION_MODERADA'
        WHEN 'ROAD_CLOSED_CONSTRUCTION' THEN 'CORTE_CONSTRUCCION'
        WHEN 'ROAD_CLOSED_EVENT' THEN 'CORTE_EVENTO'
        WHEN 'HAZARD_ON_ROAD' THEN 'PELIGRO_EN_CALZADA'
        WHEN 'HAZARD_ON_SHOULDER' THEN 'PELIGRO_EN_ACERA'
        ELSE subtype
    END as subtipo_incidente,
    
    -- Normalizar ubicación
    location.x as longitud,
    location.y as latitud,
    
    -- Normalizar descripción
    LOWER(reportDescription) as descripcion,
    
    -- Normalizar calificaciones
    reportRating as calificacion,
    confidence as confianza,
    reliability as confiabilidad,
    
    -- Normalizar información adicional
    reportByMunicipalityUser as reportado_por_municipio,
    thumbsUp as me_gusta,
    
    -- Normalizar información de ubicación
    country as pais,
    city as ciudad,
    street as calle,
    
    -- Normalizar información de tráfico
    speed as velocidad,
    delay as retraso,
    length as longitud_tramo,
    
    -- Normalizar timestamps
    ToDate(ToString(pubMillis)) as fecha_publicacion,
    ToDate(ToString(timestamp)) as fecha_actualizacion;

-- Agrupar por tipo de incidente y comuna
grouped_data = GROUP cleaned_data BY (tipo_incidente, ciudad);

-- Calcular estadísticas por grupo
stats_by_group = FOREACH grouped_data GENERATE
    group.tipo_incidente as tipo,
    group.ciudad as comuna,
    COUNT(cleaned_data) as total_incidentes,
    AVG(cleaned_data.calificacion) as promedio_calificacion,
    AVG(cleaned_data.confianza) as promedio_confianza,
    AVG(cleaned_data.retraso) as promedio_retraso,
    AVG(cleaned_data.velocidad) as promedio_velocidad;

-- Guardar resultados en Elasticsearch
STORE stats_by_group INTO 'waze_processed' USING org.elasticsearch.hadoop.pig.EsStorage(); 