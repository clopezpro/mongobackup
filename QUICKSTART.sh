#!/bin/bash
# MongoDB Backup Docker - Inicio rápido desde Docker Hub
# Uso: ./QUICKSTART.sh

set -e

echo "🐳 MongoDB Backup Docker"
echo "=========================="
echo ""
echo "Esta imagen está disponible en Docker Hub:"
echo "   clopezpro/mongo-backup:latest"
echo ""
echo "Versiones disponibles:"
echo "   • clopezpro/mongo-backup:latest (v1.0)"
echo "   • clopezpro/mongo-backup:1.0"
echo ""

# Crear estructura de directorios
mkdir -p ./secrets
mkdir -p ./backups

echo "✅ Directorios creados:"
echo "   📁 ./secrets/ - Credenciales (nunca commits a git)"
echo "   📁 ./backups/ - Respaldos"
echo ""

echo ""
echo "2️⃣  Edita los archivos en secrets/ con tus credenciales:"
echo "   • secrets/backup_username"
echo "   • secrets/backup_password"
echo "   • secrets/backup_host (usa 'mongodb' para contenedor local)"
echo "   • secrets/backup_databases (lista de DBs, una por línea o con comas)"
echo ""

echo "3️⃣  Inicia los servicios:"
echo "   docker-compose up -d"
echo ""

echo "4️⃣  Verifica que todo funciona:"
echo "   docker-compose logs backup"
echo ""

echo "✅ ¡Listo! El backup se ejecutará automáticamente según el cron configurado"
echo ""
echo "📚 Más información en: README.md"
echo "🔐 Configuración de secrets: secrets/README.md"
