#!/bin/bash

# Script para crear secrets de ejemplo
# Uso: ./create-secrets.sh

set -e

SECRETS_DIR="./secrets"

# Crear directorio si no existe
mkdir -p "${SECRETS_DIR}"

echo "🔐 Creando archivos de secrets..."

# Crear archivo de ejemplo si no existen
if [[ ! -f "${SECRETS_DIR}/backup_username" ]]; then
    echo "admin" > "${SECRETS_DIR}/backup_username"
    echo "✅ Creado: backup_username (valor: admin)"
fi

if [[ ! -f "${SECRETS_DIR}/backup_password" ]]; then
    echo "cambiar_esta_contraseña" > "${SECRETS_DIR}/backup_password"
    echo "✅ Creado: backup_password (valor: cambiar_esta_contraseña)"
fi

if [[ ! -f "${SECRETS_DIR}/backup_host" ]]; then
    echo "mongodb" > "${SECRETS_DIR}/backup_host"
    echo "✅ Creado: backup_host (valor: mongodb - contenedor interno)"
fi

if [[ ! -f "${SECRETS_DIR}/backup_databases" ]]; then
    cat > "${SECRETS_DIR}/backup_databases" <<EOF
database1
database2
database3
EOF
    echo "✅ Creado: backup_databases (ejemplo con 3 bases de datos, una por línea)"
fi

if [[ ! -f "${SECRETS_DIR}/backup_ca_cert" ]]; then
    cat > "${SECRETS_DIR}/backup_ca_cert.example" <<EOF
# Este archivo es OPCIONAL
# Solo úsalo si tu MongoDB requiere certificado SSL/TLS
# 
# Para agregar tu certificado real:
# 1. Copia tu certificado CA aquí: cp /ruta/a/ca.pem secrets/backup_ca_cert
# 2. Eliminachis este archivo .example
# 3. El script detectará automáticamente y habilitará TLS
#
# Si NO tienes este archivo, la conexión se hará sin encriptación
EOF
    chmod 644 "${SECRETS_DIR}/backup_ca_cert.example"
    echo "✅ Creado: backup_ca_cert.example (instrucciones - archivo OPCIONAL)"
fi

# --- Secretos de almacenamiento S3/R2 (OPCIONALES) --------------------------
if [[ ! -f "${SECRETS_DIR}/s3_bucket" ]]; then
    echo "mi-bucket" > "${SECRETS_DIR}/s3_bucket"
    echo "✅ Creado: s3_bucket (valor: mi-bucket)"
fi

if [[ ! -f "${SECRETS_DIR}/s3_endpoint" ]]; then
    cat > "${SECRETS_DIR}/s3_endpoint.example" <<EOF
# Endpoint S3-compatible (OPCIONAL)
#
# Cloudflare R2:  https://<ACCOUNT_ID>.r2.cloudflarestorage.com
# Backblaze B2:   https://s3.<region>.backblazeb2.com
# MinIO:          http://minio.local:9000
#
# Para AWS S3 nativo NO se define endpoint (usa el provider "AWS").
# Para usar este archivo, renombralo a s3_endpoint y pon el valor real.
EOF
    chmod 644 "${SECRETS_DIR}/s3_endpoint.example"
    echo "✅ Creado: s3_endpoint.example (instrucciones - archivo OPCIONAL)"
fi

if [[ ! -f "${SECRETS_DIR}/s3_access_key_id" ]]; then
    echo "CAMBIAR_ESTA_CLAVE" > "${SECRETS_DIR}/s3_access_key_id"
    echo "✅ Creado: s3_access_key_id (placeholder - CAMBIAR)"
fi

if [[ ! -f "${SECRETS_DIR}/s3_secret_access_key" ]]; then
    echo "CAMBIAR_ESTA_CLAVE" > "${SECRETS_DIR}/s3_secret_access_key"
    echo "✅ Creado: s3_secret_access_key (placeholder - CAMBIAR)"
fi

echo ""
echo "⚠️  IMPORTANTE:"
echo "   1. Edita los archivos en ${SECRETS_DIR}/ con tus credenciales reales"
echo "   2. Nunca commits estos archivos al repositorio"
echo "   3. Agrega 'secrets/' a .gitignore"
echo ""
echo "📝 Archivos creados:"
ls -la "${SECRETS_DIR}/"
