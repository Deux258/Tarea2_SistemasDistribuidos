/**
 * Script de inicialización de la base de datos.
 * Carga los eventos de tráfico desde el archivo JSON y los inserta en MongoDB.
 */

const fs = require("fs");

// Leer y parsear el archivo de eventos
const rawData = fs.readFileSync("/data/waze-data-collector/eventos.json");
const eventos = JSON.parse(rawData);

// Crear usuario administrador
db = db.getSiblingDB('admin');
db.createUser({
  user: 'admin',
  pwd: 'admin',
  roles: [
    { role: 'userAdminAnyDatabase', db: 'admin' },
    { role: 'readWriteAnyDatabase', db: 'admin' }
  ]
});

// Crear y configurar la base de datos
db = db.getSiblingDB("waze_db");
db.createUser({
  user: 'admin',
  pwd: 'admin',
  roles: [
    { role: 'readWrite', db: 'waze_db' }
  ]
});

console.log("✅ Usuario administrador creado con éxito.");
