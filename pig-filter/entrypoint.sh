set -e

echo "Exportando datos desde MongoDB..."
mongoexport --uri="mongodb://admin:admin123@mongo:27017/waze_db" --collection=eventos --out=/data/eventos.json --jsonArray

echo "Filtrando datos con Apache Pig..."
pig /scripts/filtrar_eventos.pig

echo "Proceso completado. Resultados en /data/eventos_filtrados.txt"