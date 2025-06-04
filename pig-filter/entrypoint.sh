#!/bin/bash

set -e

# Configuración
DATA_DIR=/data
CSV_FILE=eventos.json
FILTERED_FILE=eventos_filtrados.csv

echo "🚀 Iniciando proceso de filtrado de datos..."

# Crear directorio de datos
echo "📂 Preparando estructura de directorios..."
mkdir -p $DATA_DIR

# Esperar MongoDB
echo "🔄 Verificando conexión con MongoDB..."
until mongosh --host mongo --username admin --password admin123 --authenticationDatabase admin --eval "db.adminCommand('ping')" &> /dev/null; do
  echo "⚠️ MongoDB no responde, reintentando conexión..."
  sleep 5
done

# Exportar datos
echo "📥 Extrayendo datos de MongoDB..."
mongosh --host mongo --username admin --password admin123 --authenticationDatabase admin --eval 'db.eventos.find().toArray()' > $DATA_DIR/$CSV_FILE

# Verificar archivo
echo "🔎 Analizando archivo de eventos..."
if [ ! -s "$DATA_DIR/$CSV_FILE" ]; then
    echo "❌ Error: Archivo de eventos vacío o inexistente"
    exit 1
fi

# Ejecutar filtrado
echo "🔧 Aplicando filtros con Apache Pig..."
pig -x local /filtrar_eventos.pig

# Verificar resultado
if [ $? -eq 0 ]; then
    echo "✨ Filtrado completado con éxito"
    echo "🔍 Verificando resultados..."
    if [ -f "$DATA_DIR/$FILTERED_FILE" ]; then
        echo "📊 Archivo CSV generado en $DATA_DIR/$FILTERED_FILE"
        echo "📋 Vista previa del archivo:"
        head -n 5 "$DATA_DIR/$FILTERED_FILE"
        echo "🎯 Marcando proceso como completado..."
        touch "$DATA_DIR/filter_complete"
    else
        echo "❌ Error: Archivo CSV no generado"
        exit 1
    fi
else
    echo "❌ Error en el proceso de filtrado"
    exit 1
fi

echo "🎉 Proceso de filtrado finalizado!"