#!/bin/bash

set -e

echo "Exportando datos desde MongoDB..."
mongoexport --uri="mongodb://admin:pass@mongo_waze:27017/waze_db" \
            --collection=eventos \
            --out=/data/eventos.json \
            --jsonArray

echo "Filtrando datos con Apache Pig..."
pig -x local /filtrar_eventos.pig

echo "Creando flag de finalización..."
echo "done" > /data/filter_complete

echo "Importando resultados filtrados a la base de datos waze_filtered..."
mongoimport --uri="mongodb://admin:pass@mongo_waze:27017/waze_filtered" --collection=eventos_filtrados --file=/data/eventos_filtrados --type=csv --headerline

echo "Proceso completado. Resultados importados en la colección eventos_filtrados de waze_filtered."
#/data/eventos_filtrados"