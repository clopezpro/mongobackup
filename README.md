# MongoDB Backup con Docker Secrets

Sistema de backup automático para MongoDB usando Docker Compose y Docker Secrets, inspirado en [fradelg/docker-mysql-cron-backup](https://github.com/fradelg/docker-mysql-cron-backup).

**Características:**
- ✅ Backups automáticos según cronograma configurado
- 🔐 Credenciales seguras usando Docker Secrets
- 🔌 Soporte para túnel SSH si MongoDB está en servidor remoto
- 🗂️ Gestión automática de backups antiguos
- 📅 Backup inicial al iniciar el contenedor (opcional)
- 🎯 Múltiples bases de datos en un solo backup
- ⏰ Cron configurable

## Quick Start

### 1. Crear archivos de secrets

```bash
./create-secrets.sh
```

Esto crea archivos de ejemplo en `secrets/`. **Edita con tus credenciales reales:**

```bash
# Editar username
echo "admin" > secrets/backup_username

# Editar password
echo "tu_contraseña" > secrets/backup_password

# Editar host (mongodb para usar contenedor interno, o tu host remoto)
echo "mongodb" > secrets/backup_host

# Editar bases de datos (una por línea)
cat > secrets/backup_databases <<EOF
database1
database2
database3
EOF
```

### 2. Iniciar servicios

```bash
docker-compose up -d
```

Esto:
- Inicia MongoDB
- Inicia el contenedor de backup
- Configura el cron automático

### 3. Verificar backups

```bash
# Ver backups locales
ls -la ./backups/

# Ver logs del cron
docker-compose logs backup

# Ejecutar backup manualmente
docker-compose exec backup /app/backup-mongodb
```

## Configuración

### Variables de entorno (docker-compose.yml)

| Variable | Default | Descripción |
|----------|---------|-------------|
| `BACKUP_PORT` | 27017 | Puerto de MongoDB |
| `BACKUP_AUTHENTICATIONDATABASE` | admin | Base de datos para autenticar |
| `CRON_TIME` | 0 3 * * * | Horario del cron (3 AM diariamente) |
| `MAX_BACKUPS` | 0 | Máximo de backups a mantener (0 = ilimitado) |
| `INIT_BACKUP` | 0 | Ejecutar backup al iniciar (0 o 1) |
| `SSH_PORT` | 22 | Puerto SSH (si usas túnel) |
| `SSH_USER` | admin | Usuario SSH (si usas túnel) |
| `TZ` | UTC | Zona horaria para el cron |

### Docker Secrets (archivos en `secrets/`)

| Archivo | Descripción |
|---------|-------------|
| `backup_username` | Usuario de MongoDB |
| `backup_password` | Contraseña de MongoDB |
| `backup_host` | Host de MongoDB |
| `backup_databases` | Bases de datos a respaldar |
| `ssh_private_key` | Clave SSH en Base64 (opcional) |

## Ejemplos de configuración

### Backup local a las 3 AM, máximo 10 backups

```yaml
environment:
  - CRON_TIME=0 3 * * *
  - MAX_BACKUPS=10
  - INIT_BACKUP=0
```

### Backup cada 6 horas con ejecución inicial

```yaml
environment:
  - CRON_TIME=0 */6 * * *
  - MAX_BACKUPS=20
  - INIT_BACKUP=1
```

### Con túnel SSH a servidor remoto

1. Copia tu clave SSH privada (SIN codificar en base64):
```bash
cp ~/.ssh/id_rsa secrets/ssh_private_key
chmod 600 secrets/ssh_private_key
```

2. Configura el host remoto:
```bash
echo "mongo.example.com" > secrets/backup_host
```

3. Las variables de entorno se ajustarán automáticamente para abrir/cerrar el túnel

## Ejemplos de cron

```
0 3 * * *           Cada día a las 3 AM
0 2 * * 0           Cada domingo a las 2 AM
0 0 * * *           Cada media noche
0 */6 * * *         Cada 6 horas
0 0 1 * *           El 1º de cada mes
0 0 * * 1-5         Lunes a viernes a media noche
```

## Estructura de directorios

```
mongobackup/
├── secrets/                    # Docker secrets
│   ├── backup_username
│   ├── backup_password
│   ├── backup_host
│   ├── backup_databases
│   └── ssh_private_key        # Opcional
├── backups/                    # Backups generados
│   └── database1_2024-05-21-03-00-00/
│       ├── mongodump_version.txt
│       └── database1/
├── docker-compose.yml          # Configuración Docker Compose
├── Dockerfile                  # Imagen Docker
├── backup.sh                   # Script de backup
├── entrypoint.sh               # Punto de entrada del contenedor
├── create-secrets.sh           # Script para crear secrets de ejemplo
└── README.md
```

## Seguridad

⚠️ **IMPORTANTE:**
- Nunca commitees los archivos en `secrets/` al repositorio
- Usa `.gitignore` para excluir `secrets/` (ya incluido)
- Docker Secrets está diseñado para entornos de producción
- En desarrollo local, los secrets se almacenan en archivos regulares dentro del `secrets/` dir

## Solución de problemas

### El backup no se ejecuta

```bash
# Ver logs
docker-compose logs backup

# Ver si el cron está corriendo
docker-compose exec backup ps aux | grep cron

# Ver la configuración del cron
docker-compose exec backup cat /etc/cron.d/backup-mongodb
```

### Error de autenticación

```bash
# Verificar credenciales
docker-compose exec backup cat /run/secrets/backup_username
docker-compose exec backup cat /run/secrets/backup_password

# Probar conexión manualmente
docker-compose exec backup mongosh -u admin -p contraseña --host mongodb
```

### Túnel SSH no funciona

```bash
# Ver logs detallados
docker-compose logs backup

# Verificar que la clave SSH existe
docker-compose exec backup ls -la /run/secrets/ssh_private_key
```

## Restaurar un backup

```bash
# Ver backups disponibles
ls -la ./backups/

# Restaurar un backup específico
docker-compose exec mongodb mongorestore --username admin --password contraseña \
  /backups/database1_2024-05-21-03-00-00/database1
```

## Licencia

Basado en [docker-mysql-cron-backup](https://github.com/fradelg/docker-mysql-cron-backup) de [fradelg](https://github.com/fradelg)
