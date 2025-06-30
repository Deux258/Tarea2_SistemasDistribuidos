#!/bin/bash

#Caso de emergencia de no ejecutar correctamente el script de sincronización

echo "🚀 Iniciando importador de datos a Elasticsearch..."

# Esperar a que MongoDB esté disponible
echo "⏳ Esperando que MongoDB esté disponible..."
until python -c "
import pymongo
try:
    client = pymongo.MongoClient('mongodb://admin:admin@mongo:27017/waze_db?authSource=admin')
    client.admin.command('ping')
    print('MongoDB está disponible')
    client.close()
except Exception as e:
    print(f'Error: {e}')
    exit(1)
" 2>/dev/null; do
    echo "⏳ MongoDB no está listo aún, esperando..."
    sleep 5
done

# Esperar a que Elasticsearch esté disponible
echo "⏳ Esperando que Elasticsearch esté disponible..."
until python -c "
from elasticsearch import Elasticsearch
try:
    es = Elasticsearch('http://elasticsearch:9200')
    if es.ping():
        print('Elasticsearch está disponible')
    else:
        exit(1)
except Exception as e:
    print(f'Error: {e}')
    exit(1)
" 2>/dev/null; do
    echo "⏳ Elasticsearch no está listo aún, esperando..."
    sleep 5
done

# Verificar si hay datos en MongoDB antes de sincronizar
echo "🔍 Verificando datos en MongoDB..."
python -c "
import pymongo
try:
    client = pymongo.MongoClient('mongodb://admin:admin@mongo:27017/waze_db?authSource=admin')
    db = client['waze_db']
    collection = db['eventos']
    count = collection.count_documents({})
    print(f'Encontrados {count} eventos en MongoDB')
    if count == 0:
        print('No hay datos para sincronizar')
        exit(1)
    client.close()
except Exception as e:
    print(f'Error verificando datos: {e}')
    exit(1)
"

if [ $? -eq 0 ]; then
    echo "✅ Datos encontrados, iniciando sincronización..."
    # Ejecutar el script de sincronización
    python waze_elastic.py
else
    echo "⚠️ No hay datos para sincronizar o error al verificar"
    exit 1
fi

echo "🏁 Proceso de importación completado" 