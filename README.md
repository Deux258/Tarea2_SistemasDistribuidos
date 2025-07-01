# Sistema de Procesamiento de Eventos de Tráfico Waze

## Arquitectura del Sistema Tarea 3

El sistema está compuesto por los siguientes módulos principales:

### 1. Scraper
- **Descripción**: Módulo encargado de la extracción automatizada de datos desde el mapa en tiempo real de Waze.
- **Tecnologías**: Python, Selenium, MongoDB
- **Funcionalidades**:
  - Navegación automatizada del mapa de Waze
  - Recolección de eventos de tráfico
  - Almacenamiento en base de datos MongoDB

### 2. Data Storage
- **Descripción**: Sistema de almacenamiento para los registros de eventos.
- **Tecnologías**: MongoDB
- **Funcionalidades**:
  - Gestión de consultas rápidas
  - Soporte para actualizaciones masivas
  - Garantía de integridad y disponibilidad de datos

### 3. Filtering y Homogeneización
- **Descripción**: Módulo de limpieza y estandarización de datos.
- **Tecnologías**: Apache Pig, Hadoop
- **Funcionalidades**:
  - Eliminación de registros incompletos o erróneos
  - Estandarización de incidentes similares
  - Normalización de datos

### 4. Processing
- **Descripción**: Módulo de procesamiento y análisis de datos.
- **Tecnologías**: Apache Pig, Hadoop
- **Funcionalidades**:
  - Agrupación de incidentes por comuna
  - Análisis de frecuencia de tipos de incidentes
  - Análisis temporal de eventos
  - Implementación de caché para consultas frecuentes

## Estructura del Proyecto

```
.
├── waze-data-collector/
│   ├── scraper.py
│   └── requirements.txt
├── data-storage/
│   └── data/
│       └── pig_174890...
├── pig-filter/
│   ├── filter.pig
│   ├── Dockerfile
│   └── requirements.txt
├── pig-processor/
│   ├── process.pig
│   ├── Dockerfile
│   └── requirements.txt
├── docker-compose.yml
├── Dockerfile
└── README.md
```

NOTA: Hay más carpetas pero estas son las principales a usar para la tarea 2 (el resto pertenecen a la Tarea 1).

## Uso del Sistema

1. **Iniciar el Docker-Compose**:
```bash
docker-compose up --build
```

2. **Consultar Resultados**:
Los resultados procesados estarán disponibles en la base de datos MongoDB y pueden ser consultados a través de la API o directamente desde la base de datos.

3. Espera la carga y procesamiento de datos
El servicio waze-data-collector recolectará y cargará los datos en MongoDB (esto puede tomar varios minutos).
Una vez finalizada la carga, los módulos de filtrado y procesamiento ejecutarán los scripts de Apache Pig para limpiar y analizar los datos.

4. ejecutar el modulo "csv_loader_elastic", esto creara el indice de datos en kibana

5. ejecutar el modulo mongo_export

5. Los datos procesados estarán disponibles en la base de datos MongoDB.
Puedes acceder a Mongo Express en http://localhost:8081 para explorar la base de datos visualmente.
También puedes consultar los datos usando la API (si está implementada) o conectándote directamente a MongoDB.
Se puede acceder a elastic y kibana en http://localhost:5601 donde se obtendran los datos en la seccion discover bajo analitycs.