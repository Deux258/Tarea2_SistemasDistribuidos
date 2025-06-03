# Imagen base de MongoDB
FROM mongo:latest

# Copiar archivos de configuración
COPY init.js /docker-entrypoint-initdb.d/
COPY mongod.conf /etc/mongod.conf

RUN chown mongodb:mongodb /etc/mongod.conf

# Iniciar MongoDB con la configuración personalizada
CMD ["mongod", "--config", "/etc/mongod.conf"]