# Sistema de Procesamiento de Eventos de Tráfico Waze
Diego Muñoz Barra, Sebastián Zuñiga.


## Arquitectura del Sistema Tarea 2

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

## Instalación y Configuración

1. Para inicializar el proyecto, se ejecuta los dockers definidos en `docker-compose.yml`:
```bash
docker-compose up --build
```

2. Una vez inicializado, en los primeros minutos verá mezclado los distintos dockers hasta ejecutar `waze-data-collector` hasta subir a mongodb los 100 mil en 10 minutos aproximado.

3. Si se requiere, puede visualizar la base de datos en http://localhost:8081 usando mongo express.

4. Luego de esto, se ejecutará el filtrado con apache pig y luego el procesado con este mismo usando otro docker

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


