#!/bin/bash

set -e

# Variables por defecto
CRON_TIME=${CRON_TIME:-0 3 * * *}
INIT_BACKUP=${INIT_BACKUP:-0}
MAX_BACKUPS=${MAX_BACKUPS:-0}
BACKUP_DIRECTORY=${BACKUP_DIRECTORY:-/backups}

# Crear directorio de backups
mkdir -p "${BACKUP_DIRECTORY}"

# Exportar variables de entorno para que estén disponibles en cron
# Especialmente importante TZ para que cron use la zona horaria correcta
env | grep -E '^(BACKUP_|CRON_|INIT_|MAX_|SSH_|TZ|MONGO_)' >> /etc/environment
# Asegurar que TZ esté en /etc/environment
if ! grep -q '^TZ=' /etc/environment; then
    echo "TZ=${TZ}" >> /etc/environment
fi

# Crear script cron que ejecuta el backup
cat > /etc/cron.d/backup-mongodb <<EOF
${CRON_TIME} /app/backup-mongodb >> ${BACKUP_DIRECTORY}/cron.log 2>&1
EOF

chmod 0644 /etc/cron.d/backup-mongodb

echo "✅ Cron configurado: ${CRON_TIME}"
echo "📁 Directorio de backups: ${BACKUP_DIRECTORY}"

# Ejecutar backup inicial si está habilitado
if [[ "${INIT_BACKUP}" == "1" ]]; then
    echo "🚀 Ejecutando backup inicial..."
    /app/backup-mongodb || echo "⚠️  Backup inicial completado con estado de salida no cero (puede ser normal si hay errores de conexión)"
fi

# Iniciar cron en primer plano
exec cron -f
