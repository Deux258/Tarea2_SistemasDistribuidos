#!/bin/bash

set -e

# Configuración
HADOOP_HOME=/opt/hadoop
PIG_HOME=/opt/pig
DATA_DIR=/data
HDFS_INPUT=/input
HDFS_OUTPUT=/output
PIG_SCRIPT=/process_waze_alerts.pig
INPUT_FILE=eventos_filtrados.csv
HDFS_FILE=waze_data.csv

echo "🌐 Iniciando sistema de procesamiento distribuido..."

# 1. Iniciar servicios SSH y Hadoop
echo "🔐 Configurando servicios de red..."
sudo service ssh start

# Configurar Hadoop para Docker
echo "⚡ Configurando entorno Hadoop..."
sed -i 's/<\/configuration>/<property><name>dfs.client.use.datanode.hostname<\/name><value>false<\/value><\/property><\/configuration>/' $HADOOP_HOME/etc/hadoop/hdfs-site.xml

# Formatear HDFS si es necesario
echo "💾 Inicializando sistema de archivos..."
if [ ! -d "$HADOOP_HOME/data/namenode" ]; then
  $HADOOP_HOME/bin/hdfs namenode -format -force -nonInteractive
fi

# Iniciar servicios Hadoop
echo "🌪️ Iniciando sistema de archivos distribuido..."
$HADOOP_HOME/sbin/start-dfs.sh

# Esperar DataNodes
echo "🔄 Sincronizando nodos de datos..."
DATANODE_READY=false
for i in {1..10}; do
  if $HADOOP_HOME/bin/hdfs dfsadmin -report 2>&1 | grep -q "Live datanodes"; then
    DATANODE_READY=true
    break
  fi
  echo "⏱️ Intento $i/10: Esperando nodos de datos..."
  sleep 10
done

if [ "$DATANODE_READY" = false ]; then
  echo "❌ Error: No se detectaron nodos de datos activos"
  exit 1
fi

echo "🌪️ Iniciando sistema de procesamiento YARN..."
$HADOOP_HOME/sbin/start-yarn.sh

# 2. Configurar HDFS
echo "📁 Configurando estructura de directorios HDFS..."
$HADOOP_HOME/bin/hdfs dfs -mkdir -p $HDFS_INPUT
$HADOOP_HOME/bin/hdfs dfs -mkdir -p $HDFS_OUTPUT
$HADOOP_HOME/bin/hdfs dfs -chmod -R 755 $HDFS_INPUT
$HADOOP_HOME/bin/hdfs dfs -chmod -R 755 $HDFS_OUTPUT

# 3. Esperar archivo filtrado
echo "🔍 Buscando archivo de datos filtrados..."
while [ ! -f "$DATA_DIR/$INPUT_FILE" ]; do
  echo "⏱️ Esperando disponibilidad de $INPUT_FILE..."
  sleep 10
done

# 4. Subir archivo a HDFS
echo "📤 Cargando datos al sistema distribuido..."
$HADOOP_HOME/bin/hdfs dfs -put -f "$DATA_DIR/$INPUT_FILE" "$HDFS_INPUT/$HDFS_FILE"

# 5. Configurar Pig
echo "⚡ Configurando entorno de procesamiento Pig..."
export PIG_CLASSPATH=$HADOOP_HOME/etc/hadoop:$HADOOP_HOME/share/hadoop/common/*:$HADOOP_HOME/share/hadoop/mapreduce/*:$HADOOP_HOME/share/hadoop/hdfs/*:$HADOOP_HOME/share/hadoop/yarn/*

# 6. Esperar YARN
echo "🔄 Verificando disponibilidad de YARN..."
YARN_READY=false
for i in {1..10}; do
  if $HADOOP_HOME/bin/yarn node -list 2>/dev/null | grep -q "RUNNING"; then
    YARN_READY=true
    break
  fi
  echo "⏱️ Intento $i/10: Esperando recursos de procesamiento..."
  sleep 10
done

if [ "$YARN_READY" = false ]; then
  echo "❌ Error: Sistema de procesamiento no disponible"
  exit 1
fi

# 7. Ejecutar Pig
echo "🔧 Iniciando procesamiento distribuido..."
$PIG_HOME/bin/pig -x mapreduce -f "$PIG_SCRIPT"

if [ $? -eq 0 ]; then
  echo "✨ Procesamiento completado exitosamente"
  echo "📊 Resultados disponibles en: $HDFS_OUTPUT"
else
  echo "❌ Error en el procesamiento distribuido"
  exit 1
fi

# 8. Mantener contenedor activo
echo "🌐 Sistema de procesamiento activo y listo..."
tail -f /dev/null