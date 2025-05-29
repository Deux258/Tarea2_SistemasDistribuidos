FROM hakanserce/apache-pig

# Instalar curl para descargar el JAR
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

# Crear directorio para el JAR
RUN mkdir -p /opt/pig/lib

# Descargar elasticsearch-hadoop JAR
RUN curl -L https://artifacts.elastic.co/downloads/elasticsearch-hadoop/elasticsearch-hadoop-8.8.1.jar -o /opt/pig/lib/elasticsearch-hadoop-8.8.1.jar

# Copiar scripts de Pig
COPY ../scripts/process_waze.pig /pig-scripts/

# Configurar el punto de entrada
ENTRYPOINT ["pig", "-x", "local", "/pig-scripts/process_waze.pig"] 