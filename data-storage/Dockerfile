# Imagen base de MongoDB
FROM mongo:latest

RUN apt-get update && apt-get install -y mongodb-clients

# Copiar archivos de configuración
COPY init.js /docker-entrypoint-initdb.d/
COPY mongod.conf /etc/mongod.conf

# Iniciar MongoDB con la configuración personalizada
CMD ["mongod", "--config", "/etc/mongod.conf"]