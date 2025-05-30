FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

# Instalación básica
RUN apt-get update && \
    apt-get install -y openjdk-11-jdk wget curl python3 unzip && \
    apt-get clean

# Variables de entorno
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
ENV HADOOP_VERSION=3.3.6
ENV PIG_VERSION=0.17.0
ENV HADOOP_HOME=/opt/hadoop
ENV PIG_HOME=/opt/pig
ENV PATH=$PATH:$HADOOP_HOME/bin:$PIG_HOME/bin

# Instalar Hadoop
RUN wget https://downloads.apache.org/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz && \
    tar -xzf hadoop-${HADOOP_VERSION}.tar.gz -C /opt && \
    mv /opt/hadoop-${HADOOP_VERSION} $HADOOP_HOME && \
    rm hadoop-${HADOOP_VERSION}.tar.gz

# Instalar Pig
RUN wget https://downloads.apache.org/pig/pig-${PIG_VERSION}/pig-${PIG_VERSION}.tar.gz && \
    tar -xzf pig-${PIG_VERSION}.tar.gz -C /opt && \
    mv /opt/pig-${PIG_VERSION} $PIG_HOME && \
    rm pig-${PIG_VERSION}.tar.gz

# Crear directorio de trabajo
RUN mkdir /data
WORKDIR /data

# Copiar script Pig de procesamiento
COPY procesar_eventos.pig /data/procesar_eventos.pig

# Comando default
CMD ["pig", "-x", "local", "procesar_eventos.pig"]
