#!/bin/bash

# Configuración de las env
HADOOP_HOME=/opt/hadoop
PIG_HOME=/opt/pig
DATA_DIR=/data
HDFS_INPUT=/input
HDFS_OUTPUT=/output
PIG_SCRIPT=/scripts/filtrar_eventos.pig
PIG_SCRIPT2=/scripts/procesar_eventos.pig
CSV_FILE=eventos_waze.csv
HDFS_FILE=waze_data.csv

# Iniciar servicios SSH y Hadoop
echo "⚙️ Iniciando servicios..."
echo "Iniciando SSH..."
service ssh start

echo "Verificando si es necesario formatear NameNode "
if [ ! -d "$HADOOP_HOME/data/namenode/current" ]; then
    $HADOOP_HOME/bin/hdfs namenode -format -force
fi

ssh-keyscan -H localhost >> ~/.ssh/known_hosts 2>/dev/null
ssh-keyscan -H 0.0.0.0 >> ~/.ssh/known_hosts 2>/dev/null

echo "Iniciando HDFS (start-dfs.sh)..."
$HADOOP_HOME/sbin/start-dfs.sh

echo "Iniciando YARN (start-yarn.sh)..."
$HADOOP_HOME/sbin/start-yarn.sh

echo "⏳ Esperando inicialización de HDFS..."
sleep 10

# Configurar estructura HDFS
$HADOOP_HOME/bin/hdfs dfs -mkdir -p $HDFS_INPUT
$HADOOP_HOME/bin/hdfs dfs -mkdir -p $HDFS_OUTPUT
$HADOOP_HOME/bin/hdfs dfs -chmod -R 755 $HDFS_INPUT
$HADOOP_HOME/bin/hdfs dfs -chmod -R 755 $HDFS_OUTPUT

echo "🔍 Esperando archivo CSV..."
while [ ! -f "$DATA_DIR/$CSV_FILE" ]; do
    echo "⏳ Esperando que $CSV_FILE esté disponible..."
    sleep 15
done

# Subir archivo a HDFS con reintentos
MAX_RETRIES=3
RETRY_COUNT=0
UPLOAD_SUCCESS=false

while [ $RETRY_COUNT -lt $MAX_RETRIES ] && [ "$UPLOAD_SUCCESS" = false ]; do
    echo "⬆️ Subiendo archivo a HDFS (Intento $((RETRY_COUNT+1))/$MAX_RETRIES)..."
    $HADOOP_HOME/bin/hdfs dfs -put -f $DATA_DIR/$CSV_FILE $HDFS_INPUT/$HDFS_FILE
    if [ $? -eq 0 ]; then
        HDFS_SIZE=$($HADOOP_HOME/bin/hdfs dfs -du -s $HDFS_INPUT/$HDFS_FILE | awk '{print $1}')
        LOCAL_SIZE=$(du -b $DATA_DIR/$CSV_FILE | awk '{print $1}')
        if [ "$HDFS_SIZE" -eq "$LOCAL_SIZE" ]; then
            echo "✓ Archivo subido correctamente ($HDFS_SIZE bytes)"
            UPLOAD_SUCCESS=true
        else
            echo "✗ Los tamaños no coinciden (HDFS: $HDFS_SIZE vs Local: $LOCAL_SIZE)"
        fi
    else
        echo "✗ Falló el intento $((RETRY_COUNT+1))"
    fi
    RETRY_COUNT=$((RETRY_COUNT+1))
    sleep 5
done

if [ "$UPLOAD_SUCCESS" = false ]; then
    echo "✗ Error: No se pudo subir el archivo después de $MAX_RETRIES intentos"
    exit 1
fi

export PIG_CLASSPATH=$HADOOP_HOME/etc/hadoop:$HADOOP_HOME/share/hadoop/common/*:$HADOOP_HOME/share/hadoop/mapreduce/*:$HADOOP_HOME/share/hadoop/hdfs/*:$HADOOP_HOME/share/hadoop/yarn/*

echo "⏳ Esperando que YARN esté listo..."
until $HADOOP_HOME/bin/yarn node -list 2>/dev/null | grep -q "RUNNING"; do
    sleep 5
done

$HADOOP_HOME/bin/hdfs dfs -ls $HDFS_INPUT/$HDFS_FILE

$HADOOP_HOME/sbin/mr-jobhistory-daemon.sh start historyserver

echo "🐷 Ejecutando script Pig para la filtración de los datos"
$PIG_HOME/bin/pig -f $PIG_SCRIPT

# Puedes agregar aquí la subida de resultados filtrados y ejecución del segundo script Pig si lo necesitas
# Ejemplo:
# $HADOOP_HOME/bin/hdfs dfs -put /output/cleaned_records /input/
# $PIG_HOME/bin/pig -f $PIG_SCRIPT2

echo "✓ Procesamiento completado. Contenedor finalizado."