#!/bin/bash

set -e

echo "Esperando a que MongoDB esté disponible..."
until mongosh --host mongo --username admin --password admin123 --authenticationDatabase admin --eval "db.adminCommand('ping')" &> /dev/null; do
  echo "MongoDB no disponible, reintentando..."
  sleep 5
done

echo "Exportando datos desde MongoDB..."
mongosh --host mongo --username admin --password admin123 --authenticationDatabase admin --eval 'db.eventos.find().toArray()' > /data-storage/eventos.json

echo "Verificando archivo de eventos..."
if [ ! -s /data-storage/eventos.json ]; then
    echo "Error: El archivo de eventos está vacío o no existe"
    exit 1
fi

echo "Ejecutando script Pig para filtrar eventos..."
pig -x local /app/filtrar_eventos.pig

if [ $? -eq 0 ]; then
    echo "Proceso de filtrado completado exitosamente"
    echo "Creando flag de finalización..."
    touch /data-storage/filter_complete
else
    echo "Error en el proceso de filtrado"
    exit 1
fi

echo "Proceso de filtrado completado!"