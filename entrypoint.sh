#!/bin/bash

set -e

# Variables por defecto
CRON_TIME=${CRON_TIME:-0 3 * * *}
INIT_BACKUP=${INIT_BACKUP:-0}
MAX_BACKUPS=${MAX_BACKUPS:-0}
BACKUP_DIRECTORY=${BACKUP_DIRECTORY:-/backups}
# Subida a almacenamiento compatible con S3 (Cloudflare R2, AWS S3, ...)
UPLOAD_CRON_TIME=${UPLOAD_CRON_TIME:-0 */2 * * *}
UPLOAD_AFTER_BACKUP=${UPLOAD_AFTER_BACKUP:-1}

# Crear directorio de backups
mkdir -p "${BACKUP_DIRECTORY}"

# Exportar variables de entorno para que estén disponibles en cron
# Especialmente importante TZ para que cron use la zona horaria correcta
env | grep -E '^(BACKUP_|CRON_|INIT_|MAX_|SSH_|TZ|MONGO_|S3_|R2_|RCLONE_)' >> /etc/environment
# Asegurar que TZ esté en /etc/environment
if ! grep -q '^TZ=' /etc/environment; then
    echo "TZ=${TZ}" >> /etc/environment
fi

# Crear script cron que ejecuta el backup
cat > /etc/cron.d/backup-mongodb <<EOF
${CRON_TIME} root /app/backup-mongodb >> ${BACKUP_DIRECTORY}/cron.log 2>&1
EOF

chmod 0644 /etc/cron.d/backup-mongodb

echo "✅ Cron configurado: ${CRON_TIME}"
echo "📁 Directorio de backups: ${BACKUP_DIRECTORY}"

# --- Subida a almacenamiento S3/R2 (opcional) ------------------------------
# Si hay un bucket configurado, se programa la subida periodica
if [ -n "${S3_BUCKET:-${S3_BUCKET_FILE:-}}" ] || [ -f /etc/rclone/rclone.conf ]; then
    cat > /etc/cron.d/upload-s3 <<EOF
${UPLOAD_CRON_TIME} root /app/upload-s3.sh >> ${BACKUP_DIRECTORY}/upload-s3.log 2>&1
EOF
    chmod 0644 /etc/cron.d/upload-s3
    echo "☁️  Subida a S3/R2 configurada: ${UPLOAD_CRON_TIME}"
else
    echo "ℹ️  Sin bucket S3/R2 configurado: no se.subirá nada fuera del contenedor"
fi

# Ejecutar backup inicial si está habilitado
if [[ "${INIT_BACKUP}" == "1" ]]; then
    echo "🚀 Ejecutando backup inicial..."
    /app/backup-mongodb || echo "⚠️  Backup inicial completado con estado de salida no cero (puede ser normal si hay errores de conexión)"
    if [[ "${UPLOAD_AFTER_BACKUP}" == "1" && -x /app/upload-s3.sh ]]; then
        echo "☁️  Subiendo el backup inicial a S3/R2..."
        /app/upload-s3.sh || echo "⚠️  La subida fallo (revisar el log)"
    fi
fi

# Iniciar cron en primer plano
exec cron -f
