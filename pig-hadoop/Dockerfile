# Paso 1: Dockerfile ligero para Apache Hadoop + Pig
# Se ubicará en ./pig-hadoop/Dockerfile
FROM openjdk:11-jre-slim

# Variables de entorno
ENV HADOOP_VERSION=3.3.6
ENV PIG_VERSION=0.17.0
ENV HADOOP_HOME=/opt/hadoop
ENV PIG_HOME=/opt/pig
ENV PATH=$PATH:$HADOOP_HOME/bin:$PIG_HOME/bin

# Instalar utilidades mínimas
RUN apt-get update && \
    apt-get install -y wget curl ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Descargar e instalar Hadoop
RUN wget -qO- https://downloads.apache.org/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz \
    | tar -xz -C /opt && \
    mv /opt/hadoop-${HADOOP_VERSION} $HADOOP_HOME

# Descargar e instalar Pig
RUN wget -qO- https://downloads.apache.org/pig/pig-${PIG_VERSION}/pig-${PIG_VERSION}.tar.gz \
    | tar -xz -C /opt && \
    mv /opt/pig-${PIG_VERSION} $PIG_HOME

# Después de instalar Pig:
COPY lib/*.jar $PIG_HOME/lib/

# Crear directorio de trabajo y copiar script Pig
WORKDIR /data
COPY procesar_eventos.pig /data/

# Comando por defecto: ejecutar Pig en modo local
CMD ["pig", "-x", "local", "procesar_eventos.pig"]
