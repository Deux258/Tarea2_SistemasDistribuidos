#!/bin/bash
set -e

# Exportar datos desde MongoDB
mongoexport --uri="mongodb://admin:admin123@mongo:27017/waze_filtered?authSource=admin" --collection=eventos_filtrados --out=/data/eventos.json --jsonArray

# Ejecutar Pig
pig -x mapreduce /scripts/procesar_eventos.pig

