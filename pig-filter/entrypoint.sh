#!/bin/bash

set -e

echo "Exportando datos desde MongoDB..."
mongoexport --uri="mongodb://admin:admin123@mongo:27017/waze_db?authSource=admin" --collection=eventos --out=/data/eventos.json --jsonArray

echo "Filtrando datos con Apache Pig..."
pig -x local /filtrar_eventos.pig

echo "Importando resultados filtrados a la base de datos waze_filtered..."
mongoimport --uri="mongodb://admin:admin123@mongo:27017/waze_filtered?authSource=admin" --collection=eventos_filtrados --file=/data/eventos_filtrados --type=csv --headerline

echo "Proceso completado. Resultados importados en la colección eventos_filtrados de waze_filtered."