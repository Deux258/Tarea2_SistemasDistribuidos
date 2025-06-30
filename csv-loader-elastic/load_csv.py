from elasticsearch import Elasticsearch, helpers
import csv
import os
import sys
import time

# Variables de entorno para conexión
es_host = os.getenv("ES_HOST", "elasticsearch")
es_port = int(os.getenv("ES_PORT", "9200"))
es_scheme = os.getenv("ES_SCHEME", "http")
index_name = os.getenv("ES_INDEX_1", "raw_data")
csv_path = os.getenv("CSV_PATH_1", "/data/eventos_waze.csv")

fieldnames = [
    "uuid", "type", "city", "street", "speed", "reliability", "confidence", "country",
    "reportRating", "pubMillis", "additionalInfo", "fromNodeId", "id", "inscale",
    "magvar", "nComments", "nThumbsUp", "nearBy", "provider", "providerId",
    "reportBy", "reportByMunicipalityUser", "reportDescription", "reportMood",
    "roadType", "subtype", "toNodeId"
]

# Esperar a que Elasticsearch esté disponible
def wait_for_elasticsearch(es_url, timeout=120, interval=5):
    import requests
    start = time.time()
    while True:
        try:
            r = requests.get(es_url)
            if r.status_code == 200:
                print(f"✅ Elasticsearch disponible en {es_url}")
                return
        except Exception:
            pass
        if time.time() - start > timeout:
            print(f"❌ Elasticsearch no disponible después de {timeout} segundos en {es_url}")
            sys.exit(1)
        print(f"⏳ Esperando Elasticsearch en {es_url}...")
        time.sleep(interval)

es_url = f"http://{es_host}:{es_port}"
wait_for_elasticsearch(es_url)

# Conexión a Elasticsearch usando el mismo método que waze_elastic.py
try:
    es = Elasticsearch(
        es_url,
        request_timeout=30,
        retry_on_timeout=True,
        max_retries=3,
        http_compress=True,
        verify_certs=False
    )
    if not es.ping():
        print(f"❌ No se pudo conectar a Elasticsearch en {es_url}")
        sys.exit(1)
    print(f"✅ Conectado con éxito a Elasticsearch en {es_url}")
except Exception as e:
    print(f"❌ Error conectando a Elasticsearch: {e}")
    sys.exit(1)

# Esperar a que el archivo eventos_waze.csv esté disponible
wait_time = 10
max_retries = 30
retries = 0
while not os.path.exists(csv_path):
    if retries >= max_retries:
        print(f"❌ No se encontró el archivo después de esperar: {csv_path}")
        sys.exit(1)
    print(f"⏳ Esperando archivo: {csv_path}...")
    time.sleep(wait_time)
    retries += 1
print(f"✅ Archivo encontrado: {csv_path}")

# Crear el índice si no existe
if not es.indices.exists(index=index_name):
    es.indices.create(index=index_name)
    print(f"🆕 Índice '{index_name}' creado")
else:
    print(f"ℹ️ El índice '{index_name}' ya existe")

# Cargar datos del CSV a Elasticsearch
try:
    with open(csv_path, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f, fieldnames=fieldnames)
        next(reader, None)  # Saltar encabezado
        actions = []
        for row in reader:
            clean_row = {k: v for k, v in row.items() if k.strip() != ""}
            actions.append({
                "_index": index_name,
                "_source": clean_row
            })
    if actions:
        success, failed = helpers.bulk(es, actions, raise_on_error=False)
        print(f"✅ {success} documentos indexados correctamente en '{index_name}'.")
        if failed:
            print(f"⚠️ {len(failed)} documentos fallaron en '{index_name}'. Ejemplo:")
            print(failed[:5])
    else:
        print("⚠️ No se encontraron datos para indexar en el archivo CSV.")
except Exception as e:
    print(f"❌ Error durante la carga en '{index_name}': {e}")
    sys.exit(1)

es.indices.refresh(index=index_name)
print(f"🔄 Índice refrescado '{index_name}'")
