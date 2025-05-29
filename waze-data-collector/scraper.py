import random
import time
import json
import os
from seleniumwire import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.common.by import By
from elasticsearch import Elasticsearch
from datetime import datetime

# Configuración para el modo de visualización
USE_PYAUTOGUI = os.environ.get("DISPLAY") is not None
if USE_PYAUTOGUI:
    import pyautogui

# Configuración del recolector de datos
WAZE_MAP_URL = "https://www.waze.com/es-419/live-map/"
CHROMEDRIVER_PATH = "/usr/bin/chromedriver"
PIXELS_PER_MOVE = 300
MAX_EVENTOS = 10000

# Configuración de Elasticsearch
ELASTICSEARCH_URL = "https://my-elasticsearch-project-f2727a.es.us-east-1.aws.elastic.cloud:443"
ELASTICSEARCH_API_KEY = "OVlYTEdaY0JBMURWU1pMNHZEXzM6ejBwVFFLcklSelk3UFNSSXdDajZ0QQ=="
ELASTICSEARCH_INDEX = "waze_events"

# Direcciones de movimiento del mapa
DIRECCIONES_MAPA = {
    "arriba": (0, PIXELS_PER_MOVE),
    "abajo": (0, -PIXELS_PER_MOVE),
    "izquierda": (-PIXELS_PER_MOVE, 0),
    "derecha": (PIXELS_PER_MOVE, 0),
}

def analizar_solicitudes_red(driver, eventos):
    """
    Analiza las solicitudes de red para extraer eventos de tráfico de Waze.
    
    Args:
        driver: Instancia del navegador Chrome
        eventos: Lista donde se almacenarán los eventos encontrados
    
    Returns:
        bool: True si se alcanzó el límite de eventos, False en caso contrario
    """
    print("📡 Analizando solicitudes de red...")
    for request in driver.requests:
        if request.response and request.url.split('?')[0].endswith("georss"):
            try:
                body = request.response.body.decode('utf-8')
                data = json.loads(body)
                if 'alerts' in data:
                    for evento in data['alerts']:
                        evento.pop('comments', None)
                        eventos.append(evento)
                        if len(eventos) >= MAX_EVENTOS:
                            print("🚨 Se alcanzó el límite de 10,000 eventos.")
                            return True
            except Exception as e:
                print(f"⚠️ Error al procesar respuesta: {e}")
    return False

def configurar_navegador():
    """
    Configura y retorna una instancia del navegador Chrome con las opciones necesarias.
    
    Returns:
        webdriver.Chrome: Instancia configurada del navegador
    """
    options = Options()
    options.add_argument("--headless")
    options.add_argument("--no-sandbox")
    options.add_argument("--disable-dev-shm-usage")
    options.add_argument("--start-maximized")

    service = Service(CHROMEDRIVER_PATH)
    return webdriver.Chrome(service=service, options=options)

def guardar_eventos_elasticsearch(eventos):
    """
    Guarda los eventos recolectados en Elasticsearch.
    
    Args:
        eventos: Lista de eventos a guardar
    """
    if not eventos:
        print("⚠️ No se encontraron eventos para guardar.")
        return

    try:
        print("💾 Conectando a Elasticsearch...")
        es_client = Elasticsearch(
            ELASTICSEARCH_URL,
            api_key=ELASTICSEARCH_API_KEY,
            verify_certs=False  # Solo para desarrollo
        )

        if not es_client.ping():
            raise Exception("No se pudo conectar a Elasticsearch")

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
        if bulk_data:
            response = es_client.bulk(body=bulk_data)
            if response.get('errors'):
                print("⚠️ Algunos documentos no se insertaron correctamente.")
            else:
                print(f"✅ Se insertaron {len(eventos)} eventos en Elasticsearch.")
        else:
            print("⚠️ No hay eventos para guardar.")

    except Exception as e:
        print(f"❌ Error al guardar en Elasticsearch: {e}")

def recolectar_eventos():
    """
    Función principal que coordina el proceso de recolección de eventos de tráfico.
    """
    driver = configurar_navegador()
    driver.get(WAZE_MAP_URL)
    time.sleep(5)

    # Manejar popup inicial si existe
    try:
        acknowledge_button = driver.find_element(By.CLASS_NAME, "waze-tour-tooltip__acknowledge")
        acknowledge_button.click()
    except Exception:
        pass

    time.sleep(2)
    
    # Configurar punto central del mapa
    if USE_PYAUTOGUI:
        screenWidth, screenHeight = pyautogui.size()
        center_x = screenWidth // 2
        center_y = screenHeight // 2
        pyautogui.click(center_x, center_y)
    else:
        center_x = center_y = 500

    time.sleep(1)

    # Ajustar zoom inicial
    try:
        print("🔍 Haciendo zoom al mapa...")
        zoom_in_button = driver.find_element(By.CLASS_NAME, "leaflet-control-zoom-in")
        for _ in range(1):
            zoom_in_button.click()
            time.sleep(1)
    except Exception as e:
        print(f"⚠️ Error al hacer zoom: {e}")

    eventos = []
    print("🔄 Iniciando movimientos aleatorios del mapa...")

    # Recolectar eventos moviendo el mapa
    while len(eventos) < MAX_EVENTOS:
        direccion = random.choice(list(DIRECCIONES_MAPA.keys()))
        dx, dy = DIRECCIONES_MAPA[direccion]

        try:
            if USE_PYAUTOGUI:
                print(f"🧭 Moviendo hacia: {direccion}")
                pyautogui.moveTo(center_x, center_y)
                pyautogui.mouseDown()
                pyautogui.moveRel(dx, dy, duration=0.5)
                pyautogui.mouseUp()
                time.sleep(3)
            else:
                print(f"🧭 (Simulado) Movimiento hacia: {direccion}")
                time.sleep(1)

            if analizar_solicitudes_red(driver, eventos):
                break
        except Exception as e:
            print(f"⚠️ Error al mover el mapa: {e}")

    driver.quit()
    guardar_eventos_elasticsearch(eventos)
    print("✅ Navegación finalizada.")

if __name__ == "__main__":
    recolectar_eventos()
