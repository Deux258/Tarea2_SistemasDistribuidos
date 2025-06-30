# #!/bin/bash

# echo "🔄 Ejecutando sincronización manual..."

# # Verificar si los servicios están ejecutándose
# echo "🔍 Verificando servicios..."

# # Verificar MongoDB
# if ! python -c "
# import pymongo
# try:
#     client = pymongo.MongoClient('mongodb://admin:admin@mongo:27017/waze_db?authSource=admin')
#     client.admin.command('ping')
#     print('✅ MongoDB está disponible')
#     client.close()
# except Exception as e:
#     print(f'❌ Error MongoDB: {e}')
#     exit(1)
# " 2>/dev/null; then
#     echo "❌ MongoDB no está disponible"
#     exit 1
# fi

# # Verificar Elasticsearch
# if ! python -c "
# from elasticsearch import Elasticsearch
# try:
#     es = Elasticsearch('http://elasticsearch:9200')
#     if es.ping():
#         print('✅ Elasticsearch está disponible')
#     else:
#         exit(1)
# except Exception as e:
#     print(f'❌ Error Elasticsearch: {e}')
#     exit(1)
# " 2>/dev/null; then
#     echo "❌ Elasticsearch no está disponible"
#     exit 1
# fi

# # Ejecutar sincronización
# echo "🚀 Iniciando sincronización..."
# python simple_sync.py

# echo "✅ Sincronización manual completada" 