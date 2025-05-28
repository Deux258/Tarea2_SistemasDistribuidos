from flask import Flask, request, jsonify
import redis
from elasticsearch import Elasticsearch
import os
import json
from datetime import datetime

# Inicialización de la aplicación Flask
app = Flask(__name__)

# Configuración de Redis
REDIS_HOST = 'redis'
REDIS_PORT = 6379
redis_client = redis.Redis(host=REDIS_HOST, port=REDIS_PORT, decode_responses=True)

# Texto de prueba para simular carga en el caché
PAYLOAD_TEST = "x" * 50_000

# Configuración de Elasticsearch
ELASTICSEARCH_URL = "https://my-elasticsearch-project-f2727a.es.us-east-1.aws.elastic.cloud:443"
ELASTICSEARCH_API_KEY = "NDRVRkdaY0JBMURWU1pMNDVoaDY6WmRNY2JsMDRQcXQ3aDF2MDNwRTRpUQ=="
ELASTICSEARCH_INDEX = "waze_events"

def conectar_elasticsearch():
    """
    Establece la conexión con Elasticsearch y retorna el cliente configurado.
    
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

# Inicializar conexión a Elasticsearch
es_client = conectar_elasticsearch()

@app.route('/events', methods=['GET'])
def obtener_evento():
    """
    Endpoint para obtener un evento específico.
    Primero busca en el caché, si no está disponible, lo busca en Elasticsearch.
    
    Returns:
        JSON: Datos del evento y fuente (caché o Elasticsearch)
    """
    event_id = request.args.get('id')
    if not event_id:
        return jsonify({"error": "Debe proporcionar 'id'"}), 400

    # Intentar obtener del caché
    cache_key = f"event:{event_id}"
    cached_data = redis_client.get(cache_key)

    if cached_data:
        return jsonify({
            "source": "cache",
            "data": json.loads(cached_data)
        })

    # Si no está en caché, buscar en Elasticsearch
    try:
        result = es_client.get(index=ELASTICSEARCH_INDEX, id=event_id)
        if result and result['found']:
            event_data = result['_source']
            # Agregar payload de prueba y guardar en caché
            event_data["extra_payload"] = PAYLOAD_TEST
            redis_client.set(cache_key, json.dumps(event_data))
            return jsonify({
                "source": "elasticsearch",
                "data": event_data
            })
        else:
            return jsonify({"error": "No se encontró el evento"}), 404
    except Exception as e:
        print(f"❌ Error al buscar en Elasticsearch: {e}")
        return jsonify({"error": str(e)}), 500

@app.route('/events/ids', methods=['GET'])
def obtener_todos_ids():
    """
    Endpoint para obtener todos los IDs de eventos disponibles.
    Limitado a 10,000 eventos para evitar sobrecarga.
    
    Returns:
        JSON: Lista de IDs de eventos
    """
    try:
        # Realizar búsqueda en Elasticsearch
        search_result = es_client.search(
            index=ELASTICSEARCH_INDEX,
            body={
                "size": 10000,
                "_source": False,  # No necesitamos el contenido, solo los IDs
                "query": {
                    "match_all": {}
                }
            }
        )
        
        # Extraer IDs de los resultados
        id_list = [hit['_id'] for hit in search_result['hits']['hits']]
        return jsonify({"ids": id_list})
    except Exception as e:
        print(f"❌ Error al obtener IDs de Elasticsearch: {e}")
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
