FROM openjdk:11-jre-slim

ENV HADOOP_VERSION=3.3.6
ENV PIG_VERSION=0.17.0
ENV HADOOP_HOME=/opt/hadoop
ENV PIG_HOME=/opt/pig
ENV PATH=$PATH:$HADOOP_HOME/bin:$PIG_HOME/bin

# Instalar dependencias y MongoDB tools
RUN apt-get update && \
    apt-get install -y wget curl ca-certificates gnupg && \
    wget -qO - https://www.mongodb.org/static/pgp/server-6.0.asc | apt-key add - && \
    echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/6.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-6.0.list && \
    apt-get update && \
    apt-get install -y mongodb-database-tools && \
    rm -rf /var/lib/apt/lists/*

# Instalar Hadoop
RUN wget -qO- https://downloads.apache.org/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz \
    | tar -xz -C /opt && \
    mv /opt/hadoop-${HADOOP_VERSION} $HADOOP_HOME

# Instalar Pig
RUN wget -qO- https://downloads.apache.org/pig/pig-${PIG_VERSION}/pig-${PIG_VERSION}.tar.gz \
    | tar -xz -C /opt && \
    mv /opt/pig-${PIG_VERSION} $PIG_HOME

WORKDIR /data
COPY procesar_eventos.pig /scripts/

CMD ["pig", "-x", "mapreduce", "/scripts/procesar_eventos.pig"]