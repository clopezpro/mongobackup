#!/bin/bash
# ---------------------------------------------------------------------------
# Sube los respaldos de MongoDB a un almacenamiento compatible con S3
# (Cloudflare R2, AWS S3, Backblaze B2, MinIO, Wasabi...).
#
# Usa rclone por debajo. Las credenciales NUNCA se pasan por variables de
# entorno en tiempo de ejecucion del contenedor: se leen de archivos de
# secrets (montados) o de variables de entorno, y el archivo de configuracion
# de rclone se genera en un temporal con permisos 600 y se borra al terminar.
#
# Variables (todas soportan el sufijo _FILE para leer de un secret):
#   S3_BUCKET            bucket de destino            (obligatorio)
#   S3_PREFIX            prefijo dentro del bucket    (por defecto "backups")
#   S3_ENDPOINT          endpoint S3-compatible       (R2: https://<id>.r2.cloudflarestorage.com)
#   S3_ACCESS_KEY_ID     access key
#   S3_SECRET_ACCESS_KEY secret key
#   S3_REGION            region                       (por defecto "auto")
#   S3_PROVIDER          rclone provider              (Cloudflare | AWS | Other, por defecto "Other")
#   S3_MAX_AGE_DAYS      retencion en el bucket en dias (0 = sin retencion)
#   RCLONE_CONFIG        ruta a un rclone.conf ya existente (tiene prioridad)
#
#   BACKUP_DIRECTORY     directorio local de respaldos (por defecto /backups)
# ---------------------------------------------------------------------------
set -u

BACKUP_DIRECTORY="${BACKUP_DIRECTORY:-/backups}"

# Leer una variable desde su archivo de secret o, si no existe, del entorno
read_var() {
    local var_name="$1"
    local var_file="${var_name}_FILE"
    if [[ -n "${!var_file:-}" && -f "${!var_file}" ]]; then
        cat "${!var_file}" | tr -d '\r\n'
    else
        echo "${!var_name:-}"
    fi
}

BUCKET="$(read_var S3_BUCKET)"
PREFIX="$(read_var S3_PREFIX)"
ENDPOINT="$(read_var S3_ENDPOINT)"
ACCESS_KEY="$(read_var S3_ACCESS_KEY_ID)"
SECRET_KEY="$(read_var S3_SECRET_ACCESS_KEY)"
REGION="$(read_var S3_REGION)"
PROVIDER="$(read_var S3_PROVIDER)"
MAX_AGE_DAYS="$(read_var S3_MAX_AGE_DAYS)"
RCLONE_CONFIG="${RCLONE_CONFIG:-/etc/rclone/rclone.conf}"

PREFIX="${PREFIX:-backups}"
REGION="${REGION:-auto}"
PROVIDER="${PROVIDER:-Other}"
MAX_AGE_DAYS="${MAX_AGE_DAYS:-0}"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [upload-s3] $*"; }

if [[ -z "${BUCKET}" ]]; then
    log "S3_BUCKET no configurado: se omite la subida"
    exit 0
fi

if ! command -v rclone >/dev/null 2>&1; then
    log "ERROR: rclone no esta instalado en la imagen"
    exit 1
fi

TMP_CONFIG=""
cleanup() {
    [[ -n "${TMP_CONFIG}" && -f "${TMP_CONFIG}" ]] && rm -f "${TMP_CONFIG}"
}
trap cleanup EXIT

# --- Configuracion de rclone ------------------------------------------------
if [[ -f "${RCLONE_CONFIG}" ]]; then
    CONFIG="${RCLONE_CONFIG}"
    log "usando la configuracion existente ${CONFIG}"
else
    if [[ -z "${ACCESS_KEY}" || -z "${SECRET_KEY}" ]]; then
        log "ERROR: faltan S3_ACCESS_KEY_ID / S3_SECRET_ACCESS_KEY (o sus archivos _FILE)"
        exit 1
    fi
    TMP_CONFIG="$(mktemp)"
    chmod 600 "${TMP_CONFIG}"
    {
        echo "[s3backup]"
        echo "type = s3"
        echo "provider = ${PROVIDER}"
        echo "access_key_id = ${ACCESS_KEY}"
        echo "secret_access_key = ${SECRET_KEY}"
        [[ -n "${ENDPOINT}" ]] && echo "endpoint = ${ENDPOINT}"
        echo "region = ${REGION}"
        echo "acl = private"
        echo "no_check_bucket = true"
    } > "${TMP_CONFIG}"
    CONFIG="${TMP_CONFIG}"
    log "configuracion generada (provider=${PROVIDER}, endpoint=${ENDPOINT:-aws})"
fi

DEST="s3backup:${BUCKET}"
[[ -n "${PREFIX}" ]] && DEST="${DEST}/${PREFIX}"

# --- Subida -----------------------------------------------------------------
log "subiendo ${BACKUP_DIRECTORY} -> ${DEST}"
rclone copy "${BACKUP_DIRECTORY}" "${DEST}" \
    --config "${CONFIG}" \
    --transfers 2 \
    --checksum \
    --include "*.tar.gz" \
    --exclude "upload-s3.log" \
    --stats 30s \
    --log-level INFO

RC=$?

if [[ ${RC} -ne 0 ]]; then
    log "ERROR: la subida fallo (codigo ${RC})"
    exit ${RC}
fi

# --- Retencion (desactivada por defecto) -----------------------------------
# IMPORTANTE: la retencion en el bucket debe gestionarse con las REGLAS DE
# CICLO DE VIDA del propio R2 (Cloudflare > R2 > bucket > Settings > Object
# lifecycle > "Expire objects after N days"). Con "rclone delete --max-age"
# algunos backends S3 (R2 entre ellos) no siempre reportan la fecha de
# modificacion, y rclone puede acabar borrando archivos recien subidos.
# Por eso el borrado queda desactivado salvo que se pida de forma explicita
# con S3_ALLOW_RETENTION_DELETE=1.
if [[ "${MAX_AGE_DAYS}" -gt 0 && "${S3_ALLOW_RETENTION_DELETE:-0}" == "1" ]]; then
    log "retencion: se borran del bucket los respaldos con mas de ${MAX_AGE_DAYS} dias"
    rclone delete "${DEST}" --config "${CONFIG}" --max-age "${MAX_AGE_DAYS}d" --log-level INFO
elif [[ "${MAX_AGE_DAYS}" -gt 0 ]]; then
    log "retencion desactivada (usa las reglas de ciclo de vida de R2 para expirar objetos)"
fi

log "subida completada correctamente"
exit 0
