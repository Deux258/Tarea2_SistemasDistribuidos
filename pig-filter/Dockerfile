FROM bde2020/hadoop-base:2.0.0-hadoop3.2.1-java8

RUN sed -i 's|http://deb.debian.org/debian|http://archive.debian.org/debian|g' /etc/apt/sources.list && \
    sed -i 's|http://security.debian.org/debian-security|http://archive.debian.org/debian-security|g' /etc/apt/sources.list && \
    sed -i '/stretch-updates/d' /etc/apt/sources.list && \
    echo 'Acquire::Check-Valid-Until "false";' > /etc/apt/apt.conf.d/99no-check-valid-until && \
    apt-get update && \
    apt-get install -y gnupg wget curl && \
    wget -qO - https://www.mongodb.org/static/pgp/server-6.0.asc | apt-key add - && \
    echo "deb http://repo.mongodb.org/apt/debian bullseye/mongodb-org/6.0 main" | tee /etc/apt/sources.list.d/mongodb-org-6.0.list && \
    apt-get update && \
    apt-get install -y mongodb-mongosh && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Configurar directorios necesarios para Pig
RUN mkdir -p /data-storage && \
    mkdir -p /user/waze/output && \
    mkdir -p /user/waze/incidentes_limpios

WORKDIR /app

COPY filtrar_eventos.pig .
COPY entrypoint.sh .

# Asegurar permisos correctos
RUN chmod +x entrypoint.sh && \
    chmod 777 /data-storage && \
    chmod 777 /user/waze/output && \
    chmod 777 /user/waze/incidentes_limpios

ENTRYPOINT ["./entrypoint.sh"]