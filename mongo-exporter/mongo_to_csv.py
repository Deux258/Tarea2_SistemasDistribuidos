import os
import csv
from pymongo import MongoClient
import json
from datetime import datetime
import time
import logging
import sys

# Configuración de logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[logging.StreamHandler(sys.stdout)]
)
logger = logging.getLogger("mongo_to_csv")

# Parámetros de conexión
MONGO_HOST = os.getenv("MONGO_HOST", "mongo")
MONGO_DB = os.getenv("MONGO_DB", "waze_db")
MONGO_COLLECTION = os.getenv("MONGO_COLLECTION", "eventos")
MONGO_USER = os.getenv("MONGO_USER", "admin")
MONGO_PASS = os.getenv("MONGO_PASS", "admin")

CSV_PATH = "/data/eventos_waze.csv"
MAX_RETRIES = 10
RETRY_DELAY = 60

FIELDS = [
    'uuid', 'type', 'city', 'street', 'speed', 'reliability', 'confidence', 'country',
    'reportRating', 'pubMillis', 'additionalInfo', 'fromNodeId', 'id', 'inscale',
    'magvar', 'nComments', 'nThumbsUp', 'nearBy', 'provider', 'providerId', 'reportBy',
    'reportByMunicipalityUser', 'reportDescription', 'reportMood', 'roadType', 'subtype',
    'toNodeId'
]

def normalize_field(value):
    if value is None:
        return ""
    if isinstance(value, bool):
        return str(value).lower()
    if isinstance(value, (dict, list)):
        return json.dumps(value, ensure_ascii=False, separators=(',', ':'))
    if isinstance(value, datetime):
        return value.isoformat()
    return str(value).replace('"', '""').replace('\n', ' ').replace('\r', '')

def connect_to_mongo():
    uri = f"mongodb://{MONGO_USER}:{MONGO_PASS}@{MONGO_HOST}:27017/?authSource=admin&serverSelectionTimeoutMS=5000"
    try:
        client = MongoClient(uri, connectTimeoutMS=20000, socketTimeoutMS=None)
        client.admin.command('ping')
        logger.info("✅ Conexión a MongoDB exitosa.")
        return client
    except Exception as e:
        logger.error(f"❌ No se pudo conectar a MongoDB: {e}")
        return None

def export_eventos_to_csv():
    logger.info("🚦 Iniciando exportación de eventos desde MongoDB a CSV...")
    retries = 0
    while retries < MAX_RETRIES:
        client = connect_to_mongo()
        if not client:
            logger.warning(f"Reintentando conexión en {RETRY_DELAY} segundos...")
            time.sleep(RETRY_DELAY)
            retries += 1
            continue
        try:
            db = client[MONGO_DB]
            collection = db[MONGO_COLLECTION]
            total = collection.count_documents({})
            logger.info(f"🔎 Total de documentos en la colección '{MONGO_COLLECTION}': {total}")
            if total == 0:
                logger.warning(f"⚠️ No hay datos para exportar. Reintentando en {RETRY_DELAY} segundos...")
                time.sleep(RETRY_DELAY)
                retries += 1
                continue
            eventos = list(collection.find({}, {"_id": 0}))
            logger.info(f"📥 Extrayendo {len(eventos)} eventos...")
            with open(CSV_PATH, "w", newline="", encoding="utf-8") as csvfile:
                writer = csv.writer(csvfile, delimiter=',', quotechar='"', quoting=csv.QUOTE_MINIMAL)
                writer.writerow(FIELDS)
                for evento in eventos:
                    row = [normalize_field(evento.get(field)) for field in FIELDS]
                    writer.writerow(row)
            logger.info(f"✅ Archivo CSV generado exitosamente en {CSV_PATH}")
            logger.info(f"📊 Total de registros exportados: {len(eventos)}")
            return True
        except Exception as e:
            logger.error(f"❌ Error durante la exportación: {e}")
            retries += 1
            logger.info(f"Reintentando en {RETRY_DELAY} segundos...")
            time.sleep(RETRY_DELAY)
        finally:
            if client:
                client.close()
    logger.error("💥 Fallo crítico: No se pudo exportar la colección después de varios intentos.")
    return False

if __name__ == "__main__":
    exito = export_eventos_to_csv()
    if exito:
        logger.info("🎉 Proceso de exportación finalizado con éxito.")
    else:
        logger.error("🚨 El proceso de exportación falló.")