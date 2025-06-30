#!/bin/bash

set -e

echo "esperando señal para iniciar el proceso..."
python3 /scripts/receptor.py 

echo "Exportando datos desde MongoDB..."
mongoexport --uri="mongodb://admin:admin@mongo:27017/waze_db?authSource=admin" --collection=eventos --out=/data/eventos.json --jsonArray

#para que no existan problemas con datos ya existentes
echo "Eliminando resultados anteriores (si existen)..."
rm -rf /data/eventos_filtrados

echo "Filtrando datos con Apache Pig..."
pig -x local /filtrar_eventos.pig

echo "Los datos filtrados están disponibles en /data/eventos_filtrados"
ls -lh /data/eventos_filtrados

#echo "Importando resultados filtrados a la base de datos waze_filtered..."
#mongoimport --uri="mongodb://admin:admin@mongo:27017/waze_filtered?authSource=admin" --collection=eventos_filtrados --file=/data/eventos_filtrados --type=csv --headerline

echo "Proceso completado. Resultados importados en la colección eventos_filtrados de waze_filtered."

COPY entrypoint.sh /entrypoint.sh