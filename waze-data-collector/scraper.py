import random
import time
import json
import os
from seleniumwire import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.common.by import By
from pymongo import MongoClient

# Configuración para el modo de visualización
USE_PYAUTOGUI = os.environ.get("DISPLAY") is not None
if USE_PYAUTOGUI:
    import pyautogui

# Configuración del recolector de datos
WAZE_MAP_URL = "https://www.waze.com/es-419/live-map/"
CHROMEDRIVER_PATH = "/usr/bin/chromedriver"
PIXELS_PER_MOVE = 300
MAX_EVENTOS = 10000

# Direcciones de movimiento del mapa
DIRECCIONES_MAPA = {
    "arriba": (0, PIXELS_PER_MOVE),
    "abajo": (0, -PIXELS_PER_MOVE),
    "izquierda": (-PIXELS_PER_MOVE, 0),
    "derecha": (PIXELS_PER_MOVE, 0),
}

def analizar_solicitudes_red(driver, eventos):
    print("🔍 Revisando solicitudes de red...")
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
                            print("🛑 Se ha alcanzado el máximo de 10 mil eventos.")
                            return True
            except Exception as e:
                print(f"⚠️ Problema al procesar la respuesta: {e}")
    return False

def configurar_navegador():
    options = Options()
    options.add_argument("--headless")
    options.add_argument("--no-sandbox")
    options.add_argument("--disable-dev-shm-usage")
    options.add_argument("--start-maximized")

    service = Service(CHROMEDRIVER_PATH)
    return webdriver.Chrome(service=service, options=options)

def guardar_eventos_mongodb(eventos):
    if not eventos:
        print("ℹ️ No hay eventos para guardar.")
        return

    try:
        print("📁 Estableciendo conexión con MongoDB...")
        client = MongoClient("mongodb://admin:admin123@mongo:27017/waze_db?authSource=admin")
        db = client["waze_db"]
        collection = db["eventos"]

        result = collection.insert_many(eventos)
        print(f"\n✅ Se han guardado {len(result.inserted_ids)} eventos en MongoDB.")
    except Exception as e:
        print(f"❌ Fallo al guardar en MongoDB: {e}")

def recolectar_eventos():
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
        print("🔎 Ajustando el zoom del mapa...")
        zoom_in_button = driver.find_element(By.CLASS_NAME, "leaflet-control-zoom-in")
        for _ in range(1):
            zoom_in_button.click()
            time.sleep(1)
    except Exception as e:
        print(f"⚠️ Error al ajustar el zoom: {e}")

    eventos = []
    print("🗺️ Comenzando movimientos aleatorios del mapa...")

    # Recolectar eventos moviendo el mapa
    while len(eventos) < MAX_EVENTOS:
        direccion = random.choice(list(DIRECCIONES_MAPA.keys()))
        dx, dy = DIRECCIONES_MAPA[direccion]

        try:
            if USE_PYAUTOGUI:
                print(f"📍 Movimiento en dirección: {direccion}")
                pyautogui.moveTo(center_x, center_y)
                pyautogui.mouseDown()
                pyautogui.moveRel(dx, dy, duration=0.5)
                pyautogui.mouseUp()
                time.sleep(3)
            else:
                print(f"📍 (Simulado) Movimiento en dirección: {direccion}")
                time.sleep(1)

            if analizar_solicitudes_red(driver, eventos):
                break
        except Exception as e:
            print(f"⚠️ Error durante el movimiento del mapa: {e}")

    driver.quit()
    guardar_eventos_mongodb(eventos)
    print("🏁 Finalizando la navegación.")

    # Flag de finalización
    try:
        with open('/data/scraper_complete', 'w') as f:
            f.write('done')
        print("✅ Se ha creado el indicador de finalización correctamente")
    except Exception as e:
        print(f"⚠️ Error al crear el indicador de finalización: {e}")

    # Crea directorio si no existe
    os.makedirs('/data-storage', exist_ok=True)
    with open('/data-storage/scraper_complete', 'w') as f:
        f.write('done')

if __name__ == "__main__":
    recolectar_eventos()