#!/bin/bash

# Función para leer variable desde archivo (secrets) o usar valor directo
read_var() {
    local var_name=$1
    local var_file="${var_name}_FILE"
    
    if [[ -n ${!var_file} && -f ${!var_file} ]]; then
        # Para BACKUP_DATABASES, preservar saltos de línea; para otros, eliminarlos
        if [[ "${var_name}" == "BACKUP_DATABASES" ]]; then
            # Eliminar solo los saltos de línea al final, preservar los intermedios
            cat "${!var_file}" | sed -e 's/[[:space:]]*$//'
        else
            # Eliminar todos los caracteres de fin de línea (\r\n y \n)
            cat "${!var_file}" | tr -d '\r\n'
        fi
    else
        echo "${!var_name}"
    fi
}

BACKUP_PORT=${BACKUP_PORT:-27017}
LOCAL_PORT=${LOCAL_PORT:-27019}
SSH_PORT=${SSH_PORT:-22}
SSH_USER=${SSH_USER:-admin}
BACKUP_DIRECTORY=${BACKUP_DIRECTORY:-/backups}
BACKUP_AUTHENTICATIONDATABASE=${BACKUP_AUTHENTICATIONDATABASE:-admin}
USE_TLS=false
TLS_OPTIONS=""

SSH_CONTROL_SOCKET=/tmp/ssh_control_socket
SSH_TUNNEL_ENABLED=false
SSH_KEY_PATH=""

# Función para limpiar túnel SSH al finalizar
cleanup_ssh_tunnel() {
    if [[ "${SSH_TUNNEL_ENABLED}" == true ]]; then
        echo "🔌 Cerrando túnel SSH..."
        ssh -S "${SSH_CONTROL_SOCKET}" -O exit ${SSH_USER}@${BACKUP_HOST} 2>/dev/null
    fi
}

# Configurar trap para limpiar al finalizar o si hay error
trap cleanup_ssh_tunnel EXIT

# Leer variables desde archivos (secrets) o variables normales
BACKUP_USERNAME=$(read_var BACKUP_USERNAME)
BACKUP_PASSWORD=$(read_var BACKUP_PASSWORD)
BACKUP_HOST=$(read_var BACKUP_HOST)
BACKUP_DATABASES=$(read_var BACKUP_DATABASES)
BACKUP_CA_CERT_FILE=${BACKUP_CA_CERT_FILE:-}

if [[ -z ${BACKUP_USERNAME} ]]; then 
    echo "❌ Error: BACKUP_USERNAME no está configurada"
    exit 1
fi
if [[ -z ${BACKUP_PASSWORD} ]]; then 
    echo "❌ Error: BACKUP_PASSWORD no está configurada"
    exit 1
fi
if [[ -z ${BACKUP_HOST} ]]; then 
    echo "❌ Error: BACKUP_HOST no está configurada"
    exit 1
fi
if [[ -z ${BACKUP_DATABASES} ]]; then 
    echo "❌ Error: BACKUP_DATABASES no está configurada"
    exit 1
fi

# Verificar si existe clave SSH y usarla directamente (sin decodificar base64)
if [[ -f ${SSH_PRIVATE_KEY_FILE} ]]; then
    SSH_KEY_PATH="${SSH_PRIVATE_KEY_FILE}"
    # Verificar que sea una clave SSH válida (comienza con -----BEGIN)
    if head -1 "${SSH_KEY_PATH}" | grep -q "BEGIN"; then
        chmod 600 "${SSH_KEY_PATH}"
        SSH_TUNNEL_ENABLED=true
    else
        echo "⚠️  Advertencia: Archivo SSH_PRIVATE_KEY_FILE no parece ser una clave SSH válida"
    fi
fi


# Leer bases de datos línea por línea (ignorar líneas vacías)
readarray -t BACKUP_DATABASE_ARRAY <<< "${BACKUP_DATABASES}"

# Filtrar líneas vacías
BACKUP_DATABASE_ARRAY=($(printf '%s\n' "${BACKUP_DATABASE_ARRAY[@]}" | grep -v '^[[:space:]]*$'))

if [[ ${#BACKUP_DATABASE_ARRAY[@]} -lt 1 ]]; then
  echo "❌ Error: BACKUP_DATABASES no contiene bases de datos válidas"
  exit 1
fi

# Verificar si existe certificado SSL/TLS
if [[ -f ${BACKUP_CA_CERT_FILE} ]]; then
    echo "✅ Certificado SSL/TLS detectado, habilitando..."
    
    # Detectar versión de mongodump para usar opciones correctas
    MONGODUMP_VERSION=$(/usr/bin/mongodump --version | head -1 | grep -oP '\d+' | head -1)
    
    if [[ ${MONGODUMP_VERSION} -lt 100 ]]; then
        # Versión antigua: usa --ssl
        TLS_OPTIONS="--ssl --sslCAFile=${BACKUP_CA_CERT_FILE}"
        echo "   📌 Usando opciones antiguas: --ssl (versión < 100)"
    else
        # Versión nueva: intenta --tls primero, si falla usa --ssl
        TLS_OPTIONS="--ssl --sslCAFile=${BACKUP_CA_CERT_FILE}"
        echo "   📌 Usando opciones: --ssl (compatible con v100+)"
    fi
    chmod 444 "${BACKUP_CA_CERT_FILE}" 2>/dev/null || true
else
    echo "ℹ️  Sin certificado SSL/TLS, usando conexión sin encriptación"
fi

# Abrir túnel SSH si está habilitado
if [[ "${SSH_TUNNEL_ENABLED}" == true ]]; then
    echo "🔐 Abriendo túnel SSH..."
    echo "   📌 Conectando a: ${SSH_USER}@${SSH_HOST}:${SSH_PORT}"
    echo "   📌 Redirigiendo puerto: LOCAL:${LOCAL_PORT} → ${BACKUP_HOST}:${BACKUP_PORT}"
    # -f = background, -N = no command, -L = local port forward, -i = identity file
    # -M = master, -S = control socket para poder cerrarlo después
    ssh -i "${SSH_KEY_PATH}" \
        -f -N -M \
        -S "${SSH_CONTROL_SOCKET}" \
        -L ${LOCAL_PORT}:${BACKUP_HOST}:${BACKUP_PORT} \
        ${SSH_USER}@${SSH_HOST} \
        -p ${SSH_PORT} \
        -o StrictHostKeyChecking=no
    
    if [ $? -ne 0 ]; then
        echo "❌ Error al abrir el túnel SSH. Verifica tu llave y conexión."
        exit 1
    fi
    echo "✅ Túnel SSH abierto exitosamente"
fi

for i in "${BACKUP_DATABASE_ARRAY[@]}"; do
  if [[ -z ${i} ]]; then
    continue
  fi
  
  # Limpiar espacios en blanco
  i=$(echo "$i" | xargs)

 BACKUP_NAMEFORMAT="${i}_%Y-%m-%d-%H-%M-%S"
 BACKUP_TIMESTAMP=$(date +${BACKUP_NAMEFORMAT})
 OUTPUTDIR="${BACKUP_DIRECTORY}/${BACKUP_TIMESTAMP}"
 mkdir -p ${OUTPUTDIR}
 
 echo "📦 Haciendo backup de: ${i}"
 /usr/bin/mongodump --version | tee ${OUTPUTDIR}/mongodump_version.txt
 
 # Debug: mostrar comando que se ejecutará
 echo "   🔧 Conectando a: 127.0.0.1:${LOCAL_PORT} → base de datos: ${i}"
 if [[ -n "${TLS_OPTIONS}" ]]; then
     echo "   🔒 Opciones SSL: ${TLS_OPTIONS}"
 fi
 
 # Capturar error de mongodump en variable temporal
 MONGODUMP_OUTPUT=$(mktemp)
 /usr/bin/mongodump \
  --username="${BACKUP_USERNAME}" \
  --password="${BACKUP_PASSWORD}" \
  --host="127.0.0.1" \
  --port="${LOCAL_PORT}" \
  --db="${i}" \
  --authenticationDatabase="${BACKUP_AUTHENTICATIONDATABASE}" \
  ${TLS_OPTIONS} \
  --out="${OUTPUTDIR}" 2>&1 | tee "${MONGODUMP_OUTPUT}"
 
 MONGODUMP_EXIT=$?
 
 # Verificar si mongodump falló (por exit code o por palabra "Failed" en output)
 if [ ${MONGODUMP_EXIT} -ne 0 ] || grep -q "Failed:" "${MONGODUMP_OUTPUT}"; then
     echo ""
     echo "❌❌❌ ERROR CRÍTICO AL CONECTAR A MONGODB ❌❌❌"
     echo "La base de datos '${i}' NO se respaldaría"
     echo ""
     echo "Posibles causas:"
     echo "  • Usuario o contraseña incorrectos"
     echo "  • Host o puerto incorrectos"
     echo "  • MongoDB no está disponible en el servidor"
     echo "  • Sin permisos para respaldar la base de datos"
     echo ""
     echo "📋 Detalles del error:"
     grep "Failed:" "${MONGODUMP_OUTPUT}" || cat "${MONGODUMP_OUTPUT}"
     echo ""
     echo "🛑 Abortando backup para NO eliminar respaldos anteriores"
     echo "🧹 Limpiando directorio temporal: ${OUTPUTDIR}"
     
     # Limpiar archivos temporales (incluso si tiene subdirectorios)
     if [[ -d "${OUTPUTDIR}" ]]; then
         echo "   📁 Directorio encontrado, eliminando..."
         rm -rf "${OUTPUTDIR}"
         echo "   ✅ Directorio eliminado"
     else
         echo "   ℹ️  Directorio ya no existe"
     fi
     if [[ -f "${MONGODUMP_OUTPUT}" ]]; then
         rm -f "${MONGODUMP_OUTPUT}"
     fi
     
     # Cerrar túnel SSH antes de salir
     cleanup_ssh_tunnel
     
     exit 1
 fi
 
 rm -f "${MONGODUMP_OUTPUT}"
 
 # Comprimir el backup en tar.gz
 echo "📦 Comprimiendo backup: ${BACKUP_TIMESTAMP}.tar.gz"
 tar -czf "${BACKUP_DIRECTORY}/${BACKUP_TIMESTAMP}.tar.gz" -C "${BACKUP_DIRECTORY}" "${BACKUP_TIMESTAMP}" 2>/dev/null
 
 TAR_EXIT=$?
 if [ ${TAR_EXIT} -eq 0 ]; then
     echo "✅ Backup comprimido: ${BACKUP_TIMESTAMP}.tar.gz"
     
     # Crear enlace simbólico RELATIVO sin subshell
     # Cambiar de directorio, crear enlace, y volver
     SAVED_PWD=$(pwd)
     cd "${BACKUP_DIRECTORY}" || exit 1
     
     echo "   📍 DEBUG: PWD=$(pwd)"
     echo "   📍 DEBUG: BACKUP_TIMESTAMP=${BACKUP_TIMESTAMP}"
     echo "   📍 DEBUG: Base de datos: ${i}"
     
     rm -f "${i}-latest.tar.gz" 2>/dev/null || true
     
     # Crear enlace relativo: solo el nombre del archivo como destino
     ln -sf "${BACKUP_TIMESTAMP}.tar.gz" "${i}-latest.tar.gz"
     
     # Verificar resultado
     LINK_TARGET=$(readlink "${i}-latest.tar.gz")
     echo "   📍 DEBUG: Enlace creado: ${i}-latest.tar.gz -> ${LINK_TARGET}"
     
     # Volver al directorio anterior
     cd "${SAVED_PWD}" || exit 1
     
     echo "🔗 Enlace simbólico: ${i}-latest.tar.gz ➜ ${BACKUP_TIMESTAMP}.tar.gz"
     
     # Eliminar directorio original para ahorrar espacio
     rm -rf "${OUTPUTDIR}"
 else
     echo "❌ Error al comprimir backup (exitcode: ${TAR_EXIT})"
     exit 1
 fi

done

echo "✅✅✅ BACKUP COMPLETADO EXITOSAMENTE ✅✅✅"

# Limpiar backups antiguos si MAX_BACKUPS está configurado (solo si todo fue exitoso)
MAX_BACKUPS=${MAX_BACKUPS:-0}
if [[ ${MAX_BACKUPS} -gt 0 ]]; then
    echo "🧹 Limpiando backups antiguos (máximo: ${MAX_BACKUPS})..."
    # Contar archivos .tar.gz
    BACKUP_COUNT=$(find "${BACKUP_DIRECTORY}" -maxdepth 1 -type f -name "*_*-*-*-*-*-*.tar.gz" | wc -l)
    
    if [[ ${BACKUP_COUNT} -gt ${MAX_BACKUPS} ]]; then
        REMOVE_COUNT=$((BACKUP_COUNT - MAX_BACKUPS))
        echo "📊 Backups encontrados: ${BACKUP_COUNT}, Máximo permitido: ${MAX_BACKUPS}"
        find "${BACKUP_DIRECTORY}" -maxdepth 1 -type f -name "*_*-*-*-*-*-*.tar.gz" \
            -printf '%T@ %p\n' | \
            sort -n | \
            head -n ${REMOVE_COUNT} | \
            cut -d' ' -f2- | \
            xargs -r rm -v
        echo "✅ ${REMOVE_COUNT} backup(s) antiguo(s) eliminado(s)"
    else
        echo "✅ Todos los backups están dentro del límite (${BACKUP_COUNT}/${MAX_BACKUPS})"
    fi
fi







