#!/bin/bash
set -e

# Exportar datos desde MongoDB
mongoexport --uri="mongodb://admin:admin@mongo_waze:27017/waze_filtered" --collection=eventos_filtrados --out=/data/eventos.json --jsonArray

# Ejecutar Pig
pig -x mapreduce /scripts/procesar_eventos.pig

