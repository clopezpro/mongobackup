# 🚀 Guía Rápida de Inicio / Quick Start Guide

MongoDB Backup es un servicio Docker que realiza backups automáticos de bases de datos MongoDB con soporte para túneles SSH, compresión y limpieza automática.

**MongoDB Backup** is a Docker service that automatically backs up MongoDB databases with support for SSH tunneling, compression, and automatic cleanup.

---

## ⚡ Inicio Rápido / Quick Start

### 1️⃣ Preparar Secretos

```bash
# Crear directorio de secretos
mkdir -p secrets

# Usuario MongoDB
echo "mi_usuario" > secrets/backup_username

# Contraseña MongoDB
echo "mi_contraseña_segura" > secrets/backup_password

# Host MongoDB (puede ser IP o dominio)
echo "mongodb.ejemplo.com" > secrets/backup_host

# Bases de datos (una por línea)
echo -e "database1\ndatabase2" > secrets/backup_databases

# Clave SSH privada (si usas túnel SSH)
cat ~/.ssh/id_rsa > secrets/ssh_private_key
```

### 2️⃣ Configurar Docker Compose

```bash
# Copiar plantilla de ejemplo
cp docker-compose.example.yml docker-compose.yml

# Editar con tus valores
nano docker-compose.yml
# Cambiar:
# - SSH_HOST (servidor remoto)
# - SSH_PORT (puerto SSH)
# - TZ (tu zona horaria)
# - CRON_TIME (horario de backup)
```

### 3️⃣ Iniciar Servicio

```bash
# Iniciar en segundo plano
docker-compose up -d

# Ver logs en tiempo real
docker-compose logs -f backup

# Ejecutar backup manual
docker-compose exec backup /app/backup-mongodb
```

### 4️⃣ Verificar Backups

```bash
# Ver backups generados
ls -lh ./backups/

# Descomprimir
tar -xzf ./backups/database_name-latest.tar.gz

# Verificar contenido
tar -tzf ./backups/database_name-latest.tar.gz
```

---

## 📋 Variables Clave / Key Variables

| Variable | Descripción / Description | Ejemplo / Example |
|----------|---------------------------|-------------------|
| `TZ` | Zona horaria para cron | `America/Guayaquil` |
| `BACKUP_PORT` | Puerto MongoDB remoto | `27017` |
| `BACKUP_HOST_FILE` | **No cambiar** | `/run/secrets/backup_host` |
| `SSH_HOST` | Host del servidor remoto | `your_ip_or_host` |
| `SSH_PORT` | Puerto SSH | `your_por_ssh` |
| `SSH_USER` | Usuario SSH | `mongo_backup` |
| `CRON_TIME` | Horario backup (cron) | `0 3 * * *` |
| `MAX_BACKUPS` | Mantener últimos N backups | `10` |
| `INIT_BACKUP` | Backup al iniciar (1/0) | `1` |

---

## 📁 Estructura de Archivos / File Structure

```
mongobackup/
├── docker-compose.example.yml    # Plantilla comentada
├── docker-compose.yml             # Tu configuración (NO commitear)
├── setup.sh                        # Script de setup interactivo
├── Dockerfile
├── backup.sh                       # Script principal de backup
├── entrypoint.sh                   # Punto de entrada del contenedor
├── backups/                        # Directorio de backups (generado)
│   ├── users-latest.tar.gz        # Enlace al último backup
│   ├── users_YYYY-MM-DD-HH-MM-SS.tar.gz
│   ├── products-latest.tar.gz
│   └── products_YYYY-MM-DD-HH-MM-SS.tar.gz
└── secrets/                        # Credenciales (NO commitear)
    ├── backup_username
    ├── backup_password
    ├── backup_host
    ├── backup_databases
    ├── ssh_private_key
    └── backup_ca_cert
```

---

## 🔒 Seguridad / Security

✅ **Buenas prácticas / Best Practices:**
- Los secretos están en `./secrets/` (incluido en `.gitignore`)
- La clave SSH se monta como secret de Docker (no expuesta)
- Los backups se comprimen automáticamente
- No hay exposición de contraseñas en logs
- Limpieza automática de backups antiguos

⚠️ **IMPORTANTE / IMPORTANT:**
- **NUNCA** commitees `docker-compose.yml` con datos reales
- **NUNCA** commitees archivos en `./secrets/`
- **NUNCA** expongas tu clave SSH privada
- Usa `docker-compose.example.yml` como plantilla

---

## 🐧 Comandos Útiles / Useful Commands

```bash
# Ver logs en tiempo real
docker-compose logs -f backup

# Ver últimas 100 líneas
docker-compose logs --tail=100 backup

# Ejecutar backup manualmente
docker-compose exec backup /app/backup-mongodb

# Detener servicio
docker-compose down

# Reiniciar
docker-compose restart backup

# Acceder a la shell del contenedor
docker-compose exec backup /bin/bash

# Ver estructura de un backup
tar -tzf ./backups/database-latest.tar.gz | head -20

# Restaurar desde backup
tar -xzf ./backups/database_name-latest.tar.gz
mongorestore --db database_name ./database_name/
```

---

## 📊 Ejemplos de CRON_TIME / CRON_TIME Examples

| Cronograma / Schedule | CRON_TIME | Descripción / Description |
|-------|-----------|-----------|
| 3 AM cada día | `0 3 * * *` | Todos los días a las 3 AM |
| Cada 6 horas | `0 */6 * * *` | 00:00, 06:00, 12:00, 18:00 |
| Domingos 2 AM | `0 2 * * 0` | Una vez a la semana |
| Primer día del mes | `0 1 1 * *` | 1 AM el primer día de cada mes |
| Cada hora | `0 * * * *` | Cada hora en punto |

---

## ❌ Solución de Problemas / Troubleshooting

### Error: "Failed: error connecting to db"
```bash
# Verificar credenciales
cat secrets/backup_username
cat secrets/backup_password

# Verificar conectividad
docker-compose exec backup mongodump --version

# Probar conexión manual
docker-compose exec backup \
  mongodump --host <HOST> --port <PORT> \
  --username <USER> --password <PASS> --db test
```

### Error: "Cannot open: No such file or directory"
```bash
# Asegurar que backups/ existe y tiene permisos
mkdir -p backups
chmod 777 backups
ls -la backups/
```

### Error: "secrets: invalid secret name"
```bash
# Verificar que los archivos de secretos existen
ls -la secrets/
# Deben existir: backup_username, backup_password, backup_host, backup_databases, ssh_private_key

# Crear archivo vacío si falta
touch secrets/backup_ca_cert
```

### SSH no funciona
```bash
# Verificar clave SSH
cat secrets/ssh_private_key | head -1  # Debe mostrar: -----BEGIN RSA PRIVATE KEY-----

# Verificar permisos
chmod 600 secrets/ssh_private_key

# Probar conexión SSH manualmente
docker-compose exec backup \
  ssh -i /run/secrets/ssh_private_key -v mongo_backup@your_ip_or_host -p your_por_ssh
```

---

## 📦 Actualizaciones / Updates

```bash
# Obtener última versión
docker pull clopezpro/mongo-backup:latest

# Versión específica
docker pull clopezpro/mongo-backup:1.9

# Recrear contenedor con nueva imagen
docker-compose up -d --force-recreate
```

---

## 📚 Documentación Completa / Full Documentation

Para documentación detallada, ver:
- `README_DOCKER_HUB.md` - Características completas
- `docker-compose.example.yml` - Todas las variables comentadas
- `setup.sh` - Script interactivo de configuración

---

## 🤝 Soporte / Support

- GitHub Issues: [clopezpro/mongo-backup](https://github.com/clopezpro/mongo-backup)
- Docker Hub: [clopezpro/mongo-backup](https://hub.docker.com/r/clopezpro/mongo-backup)

---

**¡Listo! / Ready!** 🎉

Ahora tienes MongoDB Backup en funcionamiento. Los backups se ejecutarán automáticamente según el horario configurado en `CRON_TIME`.

Now you have MongoDB Backup up and running. Backups will execute automatically on the schedule defined in `CRON_TIME`.
