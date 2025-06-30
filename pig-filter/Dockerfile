FROM python:3.9-slim

# Instala dependencias básicas
RUN apt-get update && \
    apt-get install -y openjdk-17-jre-headless wget tar curl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV PATH=$PATH:$JAVA_HOME/bin

# Instalar Pig
RUN wget https://downloads.apache.org/pig/pig-0.17.0/pig-0.17.0.tar.gz && \
    tar -xzf pig-0.17.0.tar.gz && \
    mv pig-0.17.0 /opt/pig && \
    rm pig-0.17.0.tar.gz

ENV PIG_HOME=/opt/pig
ENV PATH=$PATH:$PIG_HOME/bin

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
CMD ["/entrypoint.sh"]