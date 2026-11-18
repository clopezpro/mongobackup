# 🚀 Cómo usar clopezpro/mongo-backup en otra máquina

Imagen **`clopezpro/mongo-backup`** está publicada en Docker Hub y es **100% pública**.

## Uso más simple posible

```yaml
version: '3.7'

secrets:
  backup_username:
    file: ./secrets/backup_username
  backup_password:
    file: ./secrets/backup_password
  backup_host:
    file: ./secrets/backup_host
  backup_databases:
    file: ./secrets/backup_databases

services:
 backup:
    image: clopezpro/mongo-backup:latest
    container_name: mongodb-backup
    volumes:
      - ./backups:/backups
    environment:
      - TZ=America/Guayaquil
      - BACKUP_PORT=27018
      - LOCAL_PORT=27019
      - BACKUP_AUTHENTICATIONDATABASE=admin
      - BACKUP_HOST_FILE=/run/secrets/backup_host
      - BACKUP_USERNAME_FILE=/run/secrets/backup_username
      - BACKUP_PASSWORD_FILE=/run/secrets/backup_password
      - BACKUP_DATABASES_FILE=/run/secrets/backup_databases
      - BACKUP_CA_CERT_FILE=/run/secrets/backup_ca_cert
      - SSH_PRIVATE_KEY_FILE=/run/secrets/ssh_private_key
      - SSH_USER=user_ssh_for_backup
      - SSH_HOST=ejemplo.tu-servidor.com
      - SSH_PORT=22
      - CRON_TIME=0 3 * * *
      - MAX_BACKUPS=10
      - INIT_BACKUP=1
    secrets:
      - backup_username
      - backup_password
      - backup_host
      - backup_databases
      - ssh_private_key
      - backup_ca_cert
    restart: unless-stopped

    logging:
       driver: "json-file"
       options:
       max-size: "100m"
       max-file: "3"
```

## Pasos para usar en otra máquina

### 1. Crear directorio

```bash
mkdir -p my-backup/{secrets,backups}
cd my-backup
```

### 2. Crear `docker-compose.yml`

Copia el archivo YAML anterior.

### 3. Crear archivo de credenciales

```bash
# Usuario de MongoDB
echo "admin" > secrets/backup_username

# Contraseña
echo "mi_contraseña" > secrets/backup_password

# Host donde corre MongoDB
echo "mongodb" > secrets/backup_host  # o una IP

# Bases de datos
cat > secrets/backup_databases <<EOF
mydb
another_db
EOF
```

### 4. Ejecutar

```bash
docker-compose up -d

# Ver que está corriendo
docker-compose logs -f

# Si todo bien, debería ver backups en:
ls -la ./backups/
```

## Variables disponibles

### Variables esenciales (requeridas)

| Variable | Descripción | Ejemplo |
|----------|-------------|---------|
| `BACKUP_USERNAME_FILE` | Ruta del archivo con usuario MongoDB | `/run/secrets/backup_username` |
| `BACKUP_PASSWORD_FILE` | Ruta del archivo con contraseña MongoDB | `/run/secrets/backup_password` |
| `BACKUP_HOST_FILE` | Ruta del archivo con host de MongoDB | `/run/secrets/backup_host` |
| `BACKUP_DATABASES_FILE` | Ruta del archivo con lista de bases de datos | `/run/secrets/backup_databases` |

### Variables de conexión MongoDB

| Variable | Descripción | Ejemplo | Por defecto |
|----------|-------------|---------|------------|
| `BACKUP_PORT` | Puerto de MongoDB | `27017` | `27017` |
| `BACKUP_AUTHENTICATIONDATABASE` | Base de datos de autenticación | `admin` | `admin` |
| `BACKUP_CA_CERT_FILE` | Ruta del certificado SSL/TLS (opcional) | `/run/secrets/backup_ca_cert` | - |

### Variables de SSH Tunnel (opcional)

| Variable | Descripción | Ejemplo | Por defecto |
|----------|-------------|---------|------------|
| `SSH_HOST` | Host del servidor SSH | `192.168.1.100` | - |
| `SSH_USER` | Usuario SSH | `ubuntu` | `admin` |
| `SSH_PORT` | Puerto SSH | `22` | `22` |
| `SSH_PRIVATE_KEY_FILE` | Ruta de la clave privada SSH | `/run/secrets/ssh_private_key` | - |
| `LOCAL_PORT` | Puerto local para el túnel | `27019` | `27019` |

### Variables de programación y directorio

| Variable | Descripción | Ejemplo | Por defecto |
|----------|-------------|---------|------------|
| `CRON_TIME` | Horario de ejecución (formato cron) | `0 3 * * *` | `0 3 * * *` |
| `INIT_BACKUP` | Ejecutar backup al iniciar contenedor | `1` | `0` |
| `MAX_BACKUPS` | Máximo número de backups a guardar | `10` | `0` (sin límite) |
| `BACKUP_DIRECTORY` | Directorio donde guardar backups | `/backups` | `/backups` |
| `TZ` | Zona horaria | `America/Guayaquil` | `UTC` |


### Variables de subida a S3 / Cloudflare R2 (opcional)

| Variable | Por defecto | Descripcion |
|---|---|---|
| `S3_BUCKET` | - | Bucket de destino. Si se define, se habilita la subida automatica |
| `S3_PREFIX` | `backups` | Prefijo dentro del bucket |
| `S3_ENDPOINT` | - | Endpoint S3-compatible (R2: `https://<ACCOUNT_ID>.r2.cloudflarestorage.com`) |
| `S3_ACCESS_KEY_ID` | - | Access key |
| `S3_SECRET_ACCESS_KEY` | - | Secret key |
| `S3_REGION` | `auto` | Region |
| `S3_PROVIDER` | `Other` | `Cloudflare`, `AWS` u `Other` |
| `S3_MAX_AGE_DAYS` | `0` | Retencion en el bucket (0 = sin retencion) |
| `RCLONE_CONFIG` | `/etc/rclone/rclone.conf` | Configuracion rclone existente (prioridad sobre las variables) |
| `UPLOAD_CRON_TIME` | `0 */2 * * *` | Cada cuanto se sube el contenido de `/backups` |
| `UPLOAD_AFTER_BACKUP` | `1` | Subir justo despues de cada backup |

Todas aceptan el sufijo `_FILE` (por ejemplo `S3_BUCKET_FILE=/run/secrets/s3_bucket`).

### Notas sobre las variables

- **`*_FILE`**: Apuntan a archivos dentro del contenedor (generalmente en `/run/secrets/`)
- **SSH Tunnel**: Solo se activa si `SSH_PRIVATE_KEY_FILE` existe y es válida
- **SSL/TLS**: Solo se activa si `BACKUP_CA_CERT_FILE` existe
- **Cron**: Usa la zona horaria especificada en `TZ`

## Verificar que funciona

```bash
# 1. Ver logs en tiempo real
docker-compose logs -f

# 2. Esperar ~30 segundos y ver si creó backups
ls -lh ./backups/

# 3. Ver que los .tar.gz están comprimidos correctamente
file ./backups/*.tar.gz
```

## Casos de uso avanzado

### Con SSH Tunnel

```yaml
environment:
  - SSH_HOST=192.168.1.100
  - SSH_PORT=22
  - SSH_USER=ubuntu
  - SSH_PRIVATE_KEY_FILE=/run/secrets/ssh_private_key
```

```bash
cp ~/.ssh/id_rsa secrets/ssh_private_key
```

### Con SSL/TLS

```yaml
environment:
  - BACKUP_CA_CERT_FILE=/run/secrets/backup_ca_cert
```

```bash
cp /ruta/a/ca.pem secrets/backup_ca_cert
```

---

## 🎯 Ya está lista para producción

La imagen tiene:
- ✅ Compresión automática
- ✅ Múltiples bases de datos
- ✅ Limpieza automática de backups antiguos
- ✅ Manejo de errores robusto
- ✅ SSH tunnel automático
- ✅ SSL/TLS opcional
- ✅ Cron configurable
- ✅ Zona horaria correcta

**¡Úsala en confianza! 🛡️**
