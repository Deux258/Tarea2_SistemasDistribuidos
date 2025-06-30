# Imagen base de Python
FROM python:3.9-slim

# Configuración del directorio de trabajo
WORKDIR /usr/src/app

# Copiar archivos necesarios
COPY . .

# Instalar dependencias
RUN pip install --no-cache-dir -r requirements.txt

# Exponer el puerto para la API de caché
EXPOSE 5000

# Iniciar el servicio de caché
CMD ["python", "cache.py"]
