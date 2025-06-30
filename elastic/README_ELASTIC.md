# Sincronización de Datos de Waze con Elasticsearch

Este directorio contiene scripts para sincronizar datos de eventos de Waze desde MongoDB a Elasticsearch/Kibana.

## Archivos Principales

### `waze_to_elastic.py`
- **Clase principal**: `WazeToElastic`
- **Función**: Sincroniza datos de MongoDB a Elasticsearch
- **Características**:
  - Conexión automática a MongoDB y Elasticsearch
  - Creación automática del índice `waze_eventos`
  - Mapeo optimizado para datos geoespaciales
  - Procesamiento en lotes para mejor rendimiento
  - Conversión automática de coordenadas para geo_point

### `main.py`
- **Función**: Script principal que se ejecuta al iniciar el contenedor
- **Acciones**:
  - Verifica conexiones a Elasticsearch y Kibana
  - Ejecuta sincronización inicial de datos

### `sync_monitor.py`
- **Función**: Monitor de sincronización continua
- **Características**:
  - Sincroniza datos cada 2 minutos automáticamente
  - Manejo de errores y reintentos
  - Logging detallado de operaciones

### `sync_once.py`
- **Función**: Sincronización única manual
- **Uso**: Para ejecutar una sincronización inmediata

## Configuración del Índice

El script crea automáticamente un índice llamado `waze_eventos` con el siguiente mapeo:

```json
{
  "mappings": {
    "properties": {
      "uuid": {"type": "keyword"},
      "country": {"type": "keyword"},
      "city": {"type": "keyword"},
      "type": {"type": "keyword"},
      "subtype": {"type": "keyword"},
      "location": {"type": "geo_point"},
      "pubMillis": {"type": "long"},
      "detectionDate": {"type": "date"},
      "created_at": {"type": "date"}
    }
  }
}
```

## Uso

### 1. Sincronización Automática (Recomendado)
El contenedor se ejecuta automáticamente con `docker-compose up`:

```bash
docker-compose up elastic
```

### 2. Sincronización Manual
Para ejecutar una sincronización manual:

```bash
# Dentro del contenedor
docker exec -it waze-elastic python sync_once.py

# O desde el directorio local
cd elastic
python sync_once.py
```

### 3. Monitor Continuo
Para ejecutar el monitor de sincronización continua:

```bash
docker exec -it waze-elastic python sync_monitor.py
```

## Verificación

### 1. Verificar datos en Elasticsearch
```bash
# Verificar que el índice existe
curl -X GET "localhost:9200/_cat/indices?v"

# Verificar documentos en el índice
curl -X GET "localhost:9200/waze_eventos/_count"
```

### 2. Verificar en Kibana
1. Abrir Kibana en `http://localhost:5601`
2. Ir a "Stack Management" > "Index Patterns"
3. Crear un patrón de índice para `waze_eventos`
4. Ir a "Discover" para ver los datos

## Logs

Los scripts generan logs detallados con emojis para facilitar la identificación:

- ✅ Operaciones exitosas
- ❌ Errores
- ⚠️ Advertencias
- 🔄 Procesos en curso
- ⏳ Esperas

## Troubleshooting

### Error de conexión a MongoDB
- Verificar que el contenedor `mongo` esté ejecutándose
- Verificar credenciales: `admin:admin`

### Error de conexión a Elasticsearch
- Verificar que el contenedor `elasticsearch` esté ejecutándose
- Verificar que el puerto 9200 esté accesible

### Datos no aparecen en Kibana
- Verificar que el índice `waze_eventos` existe
- Crear el patrón de índice en Kibana
- Verificar que hay datos en el índice

## Configuración Avanzada

### Modificar intervalo de sincronización
En `sync_monitor.py`, cambiar el parámetro `sync_interval`:

```python
monitor = SyncMonitor(sync_interval=300)  # 5 minutos
```

### Modificar tamaño de lotes
En `waze_to_elastic.py`, cambiar el parámetro `batch_size`:

```python
self.enviar_eventos_a_elasticsearch(batch_size=50)
``` 