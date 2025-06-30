FROM python:3.11-slim

WORKDIR /app/elastic

COPY . /app/elastic/

# Instala las dependencias necesarias
COPY requirements.txt .

RUN apt-get update && apt-get install -y curl iputils-ping && \
    pip install --no-cache-dir -r requirements.txt

# Hacer los scripts ejecutables
RUN chmod +x entrypoint.sh 
#manual_sync.sh

# Usar el entrypoint personalizado
CMD ["./entrypoint.sh"]