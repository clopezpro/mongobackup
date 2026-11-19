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


## ☁️ Subida a Cloudflare R2 (o cualquier S3-compatible)

Desde la **v1.9** la imagen incluye `rclone` y sabe subir los respaldos a un
almacenamiento compatible con S3: **Cloudflare R2**, AWS S3, Backblaze B2,
MinIO o Wasabi.

### 1. Crear el token en Cloudflare R2
`Cloudflare > R2 > Manage R2 Tokens > Create API Token` -> **Object Read & Write**
sobre el bucket que quieras usar. Anota el *Access Key ID*, el *Secret Access Key*
y el *Account ID*.

### 2. Configurar los secrets
```bash
./create-secrets.sh          # crea los archivos de ejemplo
echo "mi-bucket"              > secrets/s3_bucket
echo "https://<ACCOUNT_ID>.r2.cloudflarestorage.com" > secrets/s3_endpoint
echo "<ACCESS_KEY_ID>"        > secrets/s3_access_key_id
echo "<SECRET_ACCESS_KEY>"    > secrets/s3_secret_access_key
```

### 3. Montarlos y activarlos
```yaml
services:
  mongodb-backup:
    image: clopezpro/mongo-backup:latest
    environment:
      S3_BUCKET_FILE: /run/secrets/s3_bucket
      S3_ENDPOINT_FILE: /run/secrets/s3_endpoint
      S3_ACCESS_KEY_ID_FILE: /run/secrets/s3_access_key_id
      S3_SECRET_ACCESS_KEY_FILE: /run/secrets/s3_secret_access_key
      S3_PREFIX: backups
      S3_PROVIDER: Cloudflare
      S3_MAX_AGE_DAYS: "30"      # retencion en el bucket (0 = sin retencion)
      UPLOAD_CRON_TIME: "0 */2 * * *"   # cada cuanto se sube
    volumes:
      - ./backups:/backups
      - ./secrets/s3_bucket:/run/secrets/s3_bucket:ro
      - ./secrets/s3_endpoint:/run/secrets/s3_endpoint:ro
      - ./secrets/s3_access_key_id:/run/secrets/s3_access_key_id:ro
      - ./secrets/s3_secret_access_key:/run/secrets/s3_secret_access_key:ro
```

### Variables de la subida

| Variable | Por defecto | Descripcion |
|---|---|---|
| `S3_BUCKET` | - | Bucket de destino (obligatorio para subir) |
| `S3_PREFIX` | `backups` | Prefijo dentro del bucket |
| `S3_ENDPOINT` | - | Endpoint S3-compatible (R2: `https://<id>.r2.cloudflarestorage.com`) |
| `S3_ACCESS_KEY_ID` | - | Access key |
| `S3_SECRET_ACCESS_KEY` | - | Secret key |
| `S3_REGION` | `auto` | Region |
| `S3_PROVIDER` | `Other` | `Cloudflare`, `AWS` u `Other` |
| `S3_MAX_AGE_DAYS` | `0` | Dias de retencion (0 = sin retencion). **OJO:** el borrado automatico esta desactivado a proposito; usa las reglas de ciclo de vida de R2 |
| `S3_ALLOW_RETENTION_DELETE` | `0` | Poner a `1` para que el script borre los objetos con mas de `S3_MAX_AGE_DAYS` (peligroso: algunos backends S3 no reportan la fecha y se borra de mas) |
| `RCLONE_CONFIG` | `/etc/rclone/rclone.conf` | Configuracion rclone existente (tiene prioridad) |
| `UPLOAD_CRON_TIME` | `0 */2 * * *` | Cada cuanto se sube lo que hay en `/backups` |
| `UPLOAD_AFTER_BACKUP` | `1` | Subir justo despues de cada backup |

> Todas las variables admiten el sufijo `_FILE` para leerlas de un archivo de
> secret, que es la forma recomendada: las credenciales nunca pasan por
> variables de entorno ni por el historial del shell.
>
> Si defines `S3_BUCKET` (o montas un `rclone.conf`) la subida queda
> automatizada: se ejecuta al final de cada backup y ademas de forma periodica.
>
> **Retencion**: configura una regla de ciclo de vida en el bucket
> (`Cloudflare > R2 > respaldos > Settings > Object lifecycle > Expire objects
> after N days`). Es mas fiable que borrar desde el script, porque algunos
> backends S3 no devuelven la fecha de modificacion y el borrado por edad
> puede acabar eliminando respaldos recien subidos.

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
