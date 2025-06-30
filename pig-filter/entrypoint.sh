#!/bin/sh
set -e

INPUT_CSV=/data/eventos_waze.csv
OUTPUT_CSV=/data/eventos_filtrados.csv
PIG_SCRIPT=/scripts/filtrar_eventos.pig
PIG_SCRIPT2=/scripts/procesar_eventos.pig

if [ ! -f "$PIG_SCRIPT" ]; then
    echo "❌ Error: No se encontró $PIG_SCRIPT en el contenedor."
    exit 1
fi
if [ ! -f "$PIG_SCRIPT2" ]; then
    echo "❌ Error: No se encontró $PIG_SCRIPT2 en el contenedor."
    exit 1
fi

echo "🔍 Esperando archivo CSV..."
while [ ! -f "$INPUT_CSV" ]; do
    echo "⏳ Esperando que $INPUT_CSV esté disponible..."
    sleep 10
done

echo "🔍 Mostrando primeras líneas del CSV para depuración:"
head -n 5 "$INPUT_CSV"

# Eliminar archivo/directorio de salida si existe
if [ -e "$OUTPUT_CSV" ]; then
    echo "🧹 Eliminando salida anterior: $OUTPUT_CSV"
    rm -rf "$OUTPUT_CSV"
fi

echo "🐷 Ejecutando script Pig de filtrado..."
pig -x local -param INPUT_CSV=$INPUT_CSV -param OUTPUT_CSV=$OUTPUT_CSV $PIG_SCRIPT
if [ $? -ne 0 ]; then
    echo "❌ Error al ejecutar Pig en $PIG_SCRIPT"
    exit 2
fi

echo "✓ Filtrado completado. Archivo filtrado en $OUTPUT_CSV"

echo "\n📋 Primeros eventos filtrados (formato CSV):"
head -n 20 "$OUTPUT_CSV"

echo "🐷 Ejecutando script Pig de procesamiento..."
pig -x local $PIG_SCRIPT2

echo "✓ Procesamiento completado."