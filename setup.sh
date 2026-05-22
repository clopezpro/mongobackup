#!/bin/bash
# ==========================================
# Setup Rápido / Quick Setup Script
# ==========================================
# Este script te ayuda a configurar rápidamente MongoDB Backup
# This script helps you quickly setup MongoDB Backup
#
# Uso / Usage:
# chmod +x setup.sh
# ./setup.sh

set -e

echo "🚀 MongoDB Backup - Setup Rápido"
echo "=================================="
echo ""

# Crear directorio de secretos
echo "📁 Creando directorio de secretos..."
mkdir -p secrets

# Función para leer entrada segura
read_secret() {
    local prompt="$1"
    local varname="$2"
    read -sp "${prompt}: " value
    echo ""
    echo "$value" > "secrets/$varname"
    echo "   ✅ Guardado en secrets/$varname"
}

# Función para leer entrada normal
read_input() {
    local prompt="$1"
    local varname="$2"
    read -p "${prompt}: " value
    echo "$value" > "secrets/$varname"
    echo "   ✅ Guardado en secrets/$varname"
}

echo "📝 Configurando credenciales MongoDB..."
read_input "Usuario MongoDB" "backup_username"
read_secret "Contraseña MongoDB" "backup_password"
read_input "Host MongoDB (ej: mongodb.example.com)" "backup_host"

echo ""
echo "📋 Bases de datos a respaldar (una por línea, Enter dos veces para terminar):"
echo "Databases to backup (one per line, press Enter twice to finish):"
{
    while IFS= read -r line; do
        [ -z "$line" ] && break
        echo "$line"
    done
} > secrets/backup_databases
echo "   ✅ Guardado en secrets/backup_databases"

echo ""
echo "🔐 SSH (para túnel seguro / for secure tunneling):"
read_input "Usuario SSH en servidor remoto" "ssh_user_info"
ssh_user=$(cat secrets/ssh_user_info)
rm secrets/ssh_user_info

read -p "¿Tienes clave privada SSH? [s/n]: " has_ssh
if [ "$has_ssh" = "s" ] || [ "$has_ssh" = "S" ]; then
    read -p "Ruta a tu clave privada SSH (ej: ~/.ssh/id_rsa): " ssh_key_path
    ssh_key_path="${ssh_key_path/#\~/$HOME}"
    if [ -f "$ssh_key_path" ]; then
        cat "$ssh_key_path" > secrets/ssh_private_key
        echo "   ✅ Clave SSH importada desde: $ssh_key_path"
    else
        echo "   ❌ Archivo no encontrado: $ssh_key_path"
        echo "   ⏭️  Saltando configuración SSH"
        touch secrets/ssh_private_key
    fi
else
    echo "   ⏭️  SSH deshabilitado"
    touch secrets/ssh_private_key
fi

echo ""
echo "📦 Configuración completada!"
echo ""
echo "=== PRÓXIMOS PASOS / NEXT STEPS ==="
echo ""
echo "1. Revisa docker-compose.example.yml y cópialo a docker-compose.yml:"
echo "   Review docker-compose.example.yml and copy it to docker-compose.yml:"
echo "   $ cp docker-compose.example.yml docker-compose.yml"
echo ""
echo "2. Edita docker-compose.yml con tus valores específicos:"
echo "   Edit docker-compose.yml with your specific values:"
echo "   - SSH_HOST (servidor remoto)"
echo "   - SSH_PORT (puerto SSH)"
echo "   - TZ (tu zona horaria)"
echo "   - CRON_TIME (horario de backup)"
echo ""
echo "3. Inicia el servicio:"
echo "   Start the service:"
echo "   $ docker-compose up -d"
echo ""
echo "4. Verifica los logs:"
echo "   Check the logs:"
echo "   $ docker-compose logs -f backup"
echo ""
echo "✅ ¡Listo! / Ready!"
