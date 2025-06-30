from flask import Flask, request, jsonify
import redis
import os
import json
from elasticsearch import Elasticsearch

# Inicialización de la aplicación Flask
app = Flask(__name__)

# Configuración de Redis
REDIS_HOST = 'redis'
REDIS_PORT = 6379
redis_client = redis.Redis(host=REDIS_HOST, port=REDIS_PORT, decode_responses=True)

# Configuración de Elasticsearch
ES_HOST = os.environ.get("ES_HOST", "elasticsearch")
ES_PORT = os.environ.get("ES_PORT", "9200")
ES_INDEX = os.environ.get("ES_INDEX", "processed_data")
es = Elasticsearch([f"http://{ES_HOST}:{ES_PORT}"])

# Texto de prueba para simular carga en el caché
PAYLOAD_TEST = "x" * 50_000

@app.route('/events', methods=['GET'])
def obtener_evento():

    #Endpoint para obtener un evento específico desde Elasticsearch.
    #Primero busca en el caché Redis, si no está disponible, lo busca en Elasticsearch.
    
    event_id = request.args.get('id')
    if not event_id:
        return jsonify({"error": "Debe proporcionar 'id'"}), 400

    # Intento de obtener del caché
    cache_key = f"event:{event_id}"
    cached_data = redis_client.get(cache_key)

    if cached_data:
        return jsonify({
            "source": "cache",
            "data": json.loads(cached_data)
        })

    # Si no está en caché, buscar en Elasticsearch
    try:
        result = es.get(index=ES_INDEX, id=event_id)
        if result and result.get('_source'):
            doc = result['_source']
            doc["_id"] = event_id
            doc["extra_payload"] = PAYLOAD_TEST
            redis_client.set(cache_key, json.dumps(doc))
            return jsonify({
                "source": "elasticsearch",
                "data": doc
            })
        else:
            return jsonify({"error": "No se encontró el evento"}), 404
    except Exception as e:
        print(f"❌ Error al buscar en Elasticsearch: {e}")
        return jsonify({"error": str(e)}), 500

@app.route('/events/ids', methods=['GET'])
def obtener_todos_ids():

    #Endpoint para obtener todos los IDs de eventos disponibles en Elasticsearch.
    #Limitado a 10,000 eventos para evitar sobrecarga.

    try:
        # Buscar solo los IDs en Elasticsearch
        result = es.search(
            index=ES_INDEX,
            body={
                "size": 10000,
                "_source": False,
                "query": {"match_all": {}}
            }
        )
        id_list = [hit["_id"] for hit in result["hits"]["hits"]]
        return jsonify({"ids": id_list})
    except Exception as e:
        print(f"❌ Error al obtener IDs de Elasticsearch: {e}")
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
