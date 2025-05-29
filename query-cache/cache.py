from flask import Flask, request, jsonify
import redis
from pymongo import MongoClient
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

# Configuración de MongoDB
MONGO_URI = "mongodb://admin:admin123@mongo:27017/"
MONGO_DB = "waze_db"
MONGO_COLLECTION = "eventos"

def conectar_mongodb():
    """
    Establece la conexión con MongoDB y retorna el cliente configurado.
    
    Returns:
        pymongo.MongoClient: Cliente de MongoDB configurado
    """
    try:
        client = MongoClient(MONGO_URI)
        db = client[MONGO_DB]
        if db.command("ping"):
            print("✅ Conexión a MongoDB exitosa.")
            return client
        else:
            raise Exception("No se pudo conectar a MongoDB")
    except Exception as e:
        print(f"❌ Error al conectar con MongoDB: {e}")
        raise

# Inicializar conexión a MongoDB
mongo_client = conectar_mongodb()
db = mongo_client[MONGO_DB]
collection = db[MONGO_COLLECTION]

@app.route('/events', methods=['GET'])
def obtener_evento():
    """
    Endpoint para obtener un evento específico.
    Primero busca en el caché, si no está disponible, lo busca en MongoDB.
    
    Returns:
        JSON: Datos del evento y fuente (caché o MongoDB)
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

    # Si no está en caché, buscar en MongoDB
    try:
        result = collection.find_one({"_id": event_id})
        if result:
            # Convertir ObjectId a string para serialización JSON
            result["_id"] = str(result["_id"])
            # Agregar payload de prueba y guardar en caché
            result["extra_payload"] = PAYLOAD_TEST
            redis_client.set(cache_key, json.dumps(result))
            return jsonify({
                "source": "mongodb",
                "data": result
            })
        else:
            return jsonify({"error": "No se encontró el evento"}), 404
    except Exception as e:
        print(f"❌ Error al buscar en MongoDB: {e}")
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
        # Realizar búsqueda en MongoDB
        cursor = collection.find({}, {"_id": 1}).limit(10000)
        id_list = [str(doc["_id"]) for doc in cursor]
        return jsonify({"ids": id_list})
    except Exception as e:
        print(f"❌ Error al obtener IDs de MongoDB: {e}")
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
