#!/bin/bash

set -e

#echo "Exportando datos desde MongoDB..."
#mongoexport --uri="mongodb://admin:pass@mongo:27017/waze_db" --collection=eventos --out=/data/eventos.json --jsonArray

echo "Esperando finalización del filtro..."
while [ ! -f /data/filter_complete ]; do
  sleep 10
done

echo "Procesando datos con Apache Pig..."
pig -x local /procesar_eventos.pig

#echo "Importando resultados procesados a la base de datos waze_filtered..."
#mongoimport --uri="mongodb://admin:pass@mongo:27017/waze_filtered" --collection=eventos_filtrados --file=/data/eventos_filtrados --type=csv --headerline

#echo "Proceso completado. Resultados importados en la colección eventos_filtrados de waze_filtered."
echo "Resultados guardados en /data/resultados"