FROM python:3.9-slim

# 1. Instala dependencias básicas
RUN echo "===> Instalando dependencias básicas..." && \
    apt-get update && \
    apt-get install -y \
    openjdk-17-jre-headless \
    wget \
    tar \
    curl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 1.1 Configura JAVA_HOME para AMD64
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV PATH=$PATH:$JAVA_HOME/bin

# 2. Instalar Hadoop
RUN echo "===> Instalando Hadoop..." && \
    wget https://archive.apache.org/dist/hadoop/common/hadoop-3.2.1/hadoop-3.2.1.tar.gz && \
    tar -xzf hadoop-3.2.1.tar.gz && \
    mv hadoop-3.2.1 /opt/hadoop && \
    rm hadoop-3.2.1.tar.gz

# 2.1 Configurar Hadoop
ENV HADOOP_HOME=/opt/hadoop
ENV PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin
ENV HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop
ENV HADOOP_OPTS="-Djava.net.preferIPv4Stack=true"

# 3. Instalar Pig
RUN echo "===> Instalando Pig..." && \
    wget https://downloads.apache.org/pig/pig-0.17.0/pig-0.17.0.tar.gz && \
    tar -xzf pig-0.17.0.tar.gz && \
    mv pig-0.17.0 /opt/pig && \
    rm pig-0.17.0.tar.gz

# 3.1 Configurar entorno Pig
ENV PIG_HOME=/opt/pig
ENV PATH=$PATH:$PIG_HOME/bin

# 4. Copiar archivos de configuración de Hadoop
RUN echo "===> Copiando archivos de configuración de Hadoop..."
COPY config/core-site.xml $HADOOP_CONF_DIR/
COPY config/hdfs-site.xml $HADOOP_CONF_DIR/

# 5. Instala solo las dependencias necesarias
RUN echo "===> Instalando dependencias Python..."
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
RUN echo "===> Instalando mongoexport standalone..." && \
    apt-get update && \
    apt-get install -y wget tar && \
    wget https://fastdl.mongodb.org/tools/db/mongodb-database-tools-debian11-x86_64-100.9.4.tgz && \
    tar -xzf mongodb-database-tools-debian11-x86_64-100.9.4.tgz && \
    cp mongodb-database-tools-*/bin/mongoexport /usr/local/bin/ && \
    rm -rf mongodb-database-tools-*

# 6. Copiar el script de entrada
RUN echo "===> Copiando entrypoint.sh..."
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# 7. Copiar scripts Pig al contenedor
COPY procesar_eventos.pig /procesar_eventos.pig
COPY filtrar_eventos.pig /filtrar_eventos.pig

CMD ["/entrypoint.sh"]