from elasticsearch import Elasticsearch
import json
from datetime import datetime

# Configuración de Elasticsearch
ELASTICSEARCH_URL = "https://my-elasticsearch-project-f2727a.es.us-east-1.aws.elastic.cloud:443"
ELASTICSEARCH_API_KEY = "NDRVRkdaY0JBMURWU1pMNDVoaDY6WmRNY2JsMDRQcXQ3aDF2MDNwRTRpUQ=="
ELASTICSEARCH_INDEX = "waze_events"

def conectar_elasticsearch():
    """
    Establece la conexión con Elasticsearch.
    
    Returns:
        elasticsearch.Elasticsearch: Cliente de Elasticsearch configurado
    """
    try:
        es_client = Elasticsearch(
            ELASTICSEARCH_URL,
            api_key=ELASTICSEARCH_API_KEY,
            verify_certs=False  # Solo para desarrollo, en producción debería ser True
        )
        if es_client.ping():
            print("✅ Conexión a Elasticsearch exitosa.")
            return es_client
        else:
            raise Exception("No se pudo conectar a Elasticsearch")
    except Exception as e:
        print(f"❌ Error al conectar con Elasticsearch: {e}")
        raise

def crear_indice(es_client):
    """
    Crea el índice en Elasticsearch con el mapeo adecuado.
    
    Args:
        es_client: Cliente de Elasticsearch
    """
    # Mapeo para el índice
    mapping = {
        "mappings": {
            "properties": {
                "type": {"type": "keyword"},
                "subtype": {"type": "keyword"},
                "location": {
                    "properties": {
                        "x": {"type": "float"},
                        "y": {"type": "float"}
                    }
                },
                "reportDescription": {"type": "text"},
                "reportRating": {"type": "integer"},
                "confidence": {"type": "integer"},
                "reliability": {"type": "integer"},
                "reportByMunicipalityUser": {"type": "boolean"},
                "thumbsUp": {"type": "integer"},
                "jamUuid": {"type": "keyword"},
                "country": {"type": "keyword"},
                "city": {"type": "keyword"},
                "street": {"type": "keyword"},
                "speed": {"type": "float"},
                "delay": {"type": "integer"},
                "length": {"type": "integer"},
                "line": {"type": "geo_shape"},
                "uuid": {"type": "keyword"},
                "pubMillis": {"type": "long"},
                "timestamp": {"type": "date"}
            }
        }
    }

    # Crear índice si no existe
    if not es_client.indices.exists(index=ELASTICSEARCH_INDEX):
        es_client.indices.create(index=ELASTICSEARCH_INDEX, body=mapping)
        print(f"✅ Índice '{ELASTICSEARCH_INDEX}' creado exitosamente.")
    else:
        print(f"ℹ️ El índice '{ELASTICSEARCH_INDEX}' ya existe.")

def migrar_datos():
    """
    Migra los datos del archivo JSON a Elasticsearch.
    """
    # Conectar a Elasticsearch
    es_client = conectar_elasticsearch()
    
    # Crear índice
    crear_indice(es_client)
    
    # Leer datos del archivo JSON
    try:
        with open('eventos.json', 'r', encoding='utf-8') as f:
            eventos = json.load(f)
    except Exception as e:
        print(f"❌ Error al leer el archivo JSON: {e}")
        return

    # Preparar datos para bulk insert
    bulk_data = []
    for evento in eventos:
        # Convertir timestamp a formato ISO
        if 'pubMillis' in evento:
            evento['timestamp'] = datetime.fromtimestamp(evento['pubMillis']/1000).isoformat()
        
        # Agregar operación de índice
        bulk_data.append({"index": {"_index": ELASTICSEARCH_INDEX}})
        bulk_data.append(evento)

    # Realizar bulk insert
    try:
        if bulk_data:
            response = es_client.bulk(body=bulk_data)
            if response.get('errors'):
                print("⚠️ Algunos documentos no se insertaron correctamente.")
            else:
                print(f"✅ Se migraron {len(eventos)} eventos exitosamente.")
        else:
            print("⚠️ No hay eventos para migrar.")
    except Exception as e:
        print(f"❌ Error durante la migración: {e}")

if __name__ == "__main__":
    migrar_datos() 