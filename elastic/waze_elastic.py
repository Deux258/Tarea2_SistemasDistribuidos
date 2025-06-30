import time
from datetime import datetime
from elasticsearch import Elasticsearch
from pymongo import MongoClient
import logging

# Script para importar datos de Waze desde MongoDB a Elasticsearch

# Configurar logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(message)s')
logger = logging.getLogger(__name__)

# Desactivar logs de debug de elasticsearch
logging.getLogger('elasticsearch').setLevel(logging.WARNING)
logging.getLogger('urllib3').setLevel(logging.WARNING)
logging.getLogger('elastic_transport').setLevel(logging.WARNING)

def sync_waze_to_elastic():
    """Función principal que sincroniza datos de MongoDB a Elasticsearch"""
    
    # Conectar a MongoDB
    try:
        logger.info("🔗 Conectando a MongoDB...")
        mongo_client = MongoClient("mongodb://admin:admin@mongo:27017/waze_db?authSource=admin")
        db = mongo_client["waze_db"]
        collection = db["eventos"]
        
        # Verificar conexión
        db.command('ping')
        logger.info("✅ Conexión a MongoDB exitosa")
        
        # Obtener eventos
        eventos = list(collection.find({}))
        logger.info(f"📊 Encontrados {len(eventos)} eventos en MongoDB")
        
        if not eventos:
            logger.info("ℹ️ No hay eventos para procesar")
            return
            
    except Exception as e:
        logger.error(f"❌ Error conectando a MongoDB: {e}")
        return
    
    # Conectar a Elasticsearch
    try:
        logger.info("🔗 Conectando a Elasticsearch...")
        es = Elasticsearch(
            "http://elasticsearch:9200",
            request_timeout=30,
            retry_on_timeout=True,
            max_retries=3,
            # Configuración para reducir logs
            http_compress=True,
            verify_certs=False
        )
        
        if not es.ping():
            logger.error("❌ No se pudo conectar a Elasticsearch")
            return
            
        logger.info("✅ Conexión a Elasticsearch exitosa")
        
    except Exception as e:
        logger.error(f"❌ Error conectando a Elasticsearch: {e}")
        return
    
    # Crear índice si no existe
    index_name = "waze_eventos"
    try:
        if not es.indices.exists(index=index_name):
            logger.info(f"📝 Creando índice '{index_name}'...")
            
            # Mapeo simple para los datos
            mapping = {
                    "mappings": {
                        "properties": {
                            "uuid": {"type": "keyword"},
                            "country": {"type": "keyword"},
                            "city": {"type": "keyword"},
                            "reportMood": {"type": "keyword"},
                            "reliability": {"type": "integer"},
                            "reportRating": {"type": "integer"},
                            "confidence": {"type": "integer"},
                            "type": {"type": "keyword"},
                            "subtype": {"type": "keyword"},
                            "location": {
                                "type": "geo_point"
                            },
                            "pubMillis": {"type": "long"},
                            "reportDescription": {"type": "text"},
                            "reportByMunicipalityUser": {"type": "boolean"},
                            "jamUuid": {"type": "keyword"},
                            "speed": {"type": "float"},
                            "speedKMH": {"type": "float"},
                            "length": {"type": "integer"},
                            "delay": {"type": "integer"},
                            "line": {"type": "geo_shape"},
                            "segments": {"type": "nested"},
                            "blockingAlertUuid": {"type": "keyword"},
                            "detectionDate": {"type": "date"},
                            "created_at": {"type": "date"}
                        }
                    },
                    "settings": {
                        "number_of_shards": 1,
                        "number_of_replicas": 0
                    }
                }
            
            es.indices.create(index=index_name, body=mapping)
            logger.info("✅ Índice creado exitosamente")
        else:
            logger.info("ℹ️ El índice ya existe")
            
    except Exception as e:
        logger.error(f"❌ Error creando índice: {e}")
        return
    
    # Procesar y enviar eventos
    try:
        logger.info("📤 Enviando eventos a Elasticsearch...")
        
        for i, evento in enumerate(eventos):
            # Remover _id de MongoDB
            evento.pop('_id', None)
            
            # Agregar timestamp
            evento['created_at'] = datetime.now().isoformat()
            
            # Convertir coordenadas si existen
            if 'location' in evento and 'y' in evento['location'] and 'x' in evento['location']:
                evento['location'] = {
                    "lat": evento['location']['y'],
                    "lon": evento['location']['x']
                }
            
            # Enviar a Elasticsearch (silenciosamente)
            try:
                es.index(
                    index=index_name,
                    id=evento.get('uuid', None),
                    body=evento,
                    # Configuración para reducir logs
                    request_timeout=10,
                    ignore=400  # Ignorar errores de documentos duplicados
                )
                
                # Solo mostrar progreso cada 100 eventos
                if (i + 1) % 100 == 0:
                    logger.info(f"📤 Procesados {i + 1}/{len(eventos)} eventos")
                    
            except Exception as e:
                # Solo mostrar errores críticos, no cada documento individual
                if "document already exists" not in str(e).lower():
                    logger.warning(f"⚠️ Error enviando evento {i}: {e}")
                continue
        
        logger.info(f"✅ Proceso completado. {len(eventos)} eventos enviados a Elasticsearch")
        
        # Verificar datos en Elasticsearch
        count = es.count(index=index_name)
        logger.info(f"📊 Total de eventos en Elasticsearch: {count['count']}")
        
    except Exception as e:
        logger.error(f"❌ Error procesando eventos: {e}")

def main():
    # Función principal para ejecutar la sincronización
    logger.info("🚀 Iniciando sincronización de datos de Waze a Elasticsearch")
    
    # Esperar un poco para que los servicios estén listos
    logger.info("⏳ Esperando que los servicios estén disponibles...")
    time.sleep(10)
    
    # Ejecutar sincronización
    sync_waze_to_elastic()
    
    logger.info("🏁 Proceso finalizado")

if __name__ == "__main__":
    main() 