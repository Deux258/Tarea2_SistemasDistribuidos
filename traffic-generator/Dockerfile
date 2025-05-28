# Imagen base de Python
FROM python:3.9-slim

# Configuración del directorio de trabajo
WORKDIR /usr/src/app

# Copiar el generador de tráfico
COPY generator.py .

# Instalar dependencias necesarias
RUN pip install --upgrade pip && \
    pip install --no-cache-dir requests numpy scipy

# Crear directorio para logs
RUN mkdir -p logs

# Iniciar el generador de tráfico
CMD ["python", "generator.py"]
