import random
import time
import logging
import os
import requests
from datetime import datetime
from collections import defaultdict
import numpy as np
import json

# Configuración del directorio de logs
LOGS_DIR = 'logs'
if not os.path.exists(LOGS_DIR):
    os.makedirs(LOGS_DIR)

# Configuración del logging
logging.basicConfig(
    filename=f'{LOGS_DIR}/traffic_generator.log',
    level=logging.INFO,
    format='%(asctime)s - %(message)s'
)

# Contadores globales para estadísticas
cache_hits = 0
cache_misses = 0
total_requests = 0
event_access_count = defaultdict(int)

# Estadísticas detalladas por ID de evento
event_statistics = defaultdict(lambda: {
    "requests": 0,
    "hits": 0,
    "misses": 0,
    "total_time": 0.0
})

# Configuración de endpoints
CACHE_API_URL = "http://redis-cache:5000/events"
EVENT_IDS_URL = "http://redis-cache:5000/events/ids"

# Configuración de distribuciones
DISTRIBUTION_TYPE = 0  # 0: Exponencial, 1: Uniforme

# Parámetros de la distribución exponencial
EXPONENTIAL_SCALE_MIN = 0.2
EXPONENTIAL_SCALE_MAX = 5.0
EXPONENTIAL_SCALE_INCREMENT = 0.3
current_exponential_scale = EXPONENTIAL_SCALE_MIN

def obtener_eventos_aleatorios(tamaño_muestra=100):
    try:
        response = requests.get(EVENT_IDS_URL)
        if response.status_code == 200:
            todos_ids = response.json().get("ids", [])
            return random.sample(todos_ids, tamaño_muestra)
        else:
            logging.error(f"❌ Error al obtener IDs: {response.status_code}")
            return []
    except Exception as e:
        logging.error(f"💥 Excepción al obtener IDs: {e}")
        return []

def generar_plan_solicitudes(ids_seleccionados, min_repeticiones=1, max_repeticiones=3, 
                           longitud_objetivo=60, num_ids_frecuentes=10):
    plan_solicitudes = []

    # Seleccionar IDs frecuentes y no frecuentes
    ids_frecuentes = random.sample(ids_seleccionados, num_ids_frecuentes)
    ids_no_frecuentes = list(set(ids_seleccionados) - set(ids_frecuentes))

    # Generar solicitudes para IDs frecuentes
    while len(plan_solicitudes) < longitud_objetivo:
        for _id in ids_frecuentes:
            repeticiones = random.randint(2, max_repeticiones)
            plan_solicitudes.extend([_id] * repeticiones)
            if len(plan_solicitudes) >= longitud_objetivo:
                break

        # Generar solicitudes para IDs no frecuentes
        for _id in random.sample(ids_no_frecuentes, min(len(ids_no_frecuentes), 10)):
            repeticiones = random.randint(1, 2)
            plan_solicitudes.extend([_id] * repeticiones)
            if len(plan_solicitudes) >= longitud_objetivo:
                break

    random.shuffle(plan_solicitudes)
    return plan_solicitudes[:longitud_objetivo]

def procesar_solicitud(event_id):
    global cache_hits, cache_misses, total_requests

    event_access_count[event_id] += 1
    total_requests += 1
    params = {"id": event_id}

    start_time = time.time()
    try:
        response = requests.get(CACHE_API_URL, params=params)
        elapsed_time = time.time() - start_time

        event_statistics[event_id]["requests"] += 1
        event_statistics[event_id]["total_time"] += elapsed_time

        if response.status_code == 200:
            result = response.json()
            source = result.get("source", "unknown")
            current_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

            if source == "cache":
                cache_hits += 1
                event_statistics[event_id]["hits"] += 1
                log = f"[CACHE HIT] id={event_id} at {current_time} | Time: {elapsed_time:.3f}s"
            else:
                cache_misses += 1
                event_statistics[event_id]["misses"] += 1
                log = f"[CACHE MISS] id={event_id} at {current_time} | Time: {elapsed_time:.3f}s"

            print(log)
            logging.info(log)

            if total_requests % 10 == 0:
                hit_rate = (cache_hits / total_requests) * 100
                miss_rate = (cache_misses / total_requests) * 100
                stats = f"Total Requests: {total_requests} | Hits: {cache_hits} | Misses: {cache_misses} | Hit Rate: {hit_rate:.2f}% | Miss Rate: {miss_rate:.2f}%"
                print(stats)
                logging.info(stats)
        else:
            logging.warning(f"❌ Error {response.status_code} for id={event_id}")
    except Exception as e:
        logging.error(f"💥 Excepción durante la solicitud: {e}")

    return elapsed_time

def generar_trafico():
    global current_exponential_scale

    # Obtener IDs de eventos
    ids_seleccionados = obtener_eventos_aleatorios(1000)
    if not ids_seleccionados:
        print("No se pudieron obtener los IDs de eventos.")
        return
    print(f"✅ IDs seleccionados: {ids_seleccionados}")

    ciclo_count = 0

    while True:
        plan_solicitudes = generar_plan_solicitudes(ids_seleccionados)
        
        # Procesar cada solicitud según la distribución seleccionada
        for event_id in plan_solicitudes:
            procesar_solicitud(event_id)
            
            # Aplicar tiempo de espera según la distribución
            if DISTRIBUTION_TYPE == 1:
                wait_time = random.uniform(0.1, 1)
            else:
                wait_time = np.random.exponential(scale=current_exponential_scale)
            time.sleep(wait_time)

        # Actualizar escala exponencial cada 10 ciclos
        ciclo_count += 1
        if ciclo_count % 10 == 0:
            current_exponential_scale = min(current_exponential_scale + EXPONENTIAL_SCALE_INCREMENT, 
                                         EXPONENTIAL_SCALE_MAX)

        # Guardar estadísticas
        with open(f"{LOGS_DIR}/event_statistics.json", "w") as f:
            json.dump(event_statistics, f, indent=4)

        print("\n🔄 Generando nuevo ciclo de solicitudes...\n")
        logging.info("🔄 Generando nuevo ciclo de solicitudes...")
        time.sleep(2)

if __name__ == "__main__":
    generar_trafico()
