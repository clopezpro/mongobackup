# Deployment: Usar MongoDB Backup desde Docker Hub 🚀

Esta guía explica cómo usar la imagen `clopezpro/mongo-backup` publicada en Docker Hub en tu máquina.

## Opción 1: Uso simple (sin documentación local)

Si solo quieres usar la imagen sin clonar el repositorio:

### 1. Crear directorio de proyecto

```bash
mkdir -p my-mongo-backup/{secrets,backups}
cd my-mongo-backup
```

### 2. Crear `docker-compose.yml`

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
  ssh_private_key:
    file: ./secrets/ssh_private_key
  backup_ca_cert:
    file: ./secrets/backup_ca_cert

services:
 backup-mongo:
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

### 3. Crear archivos de secretos

```bash
# Credenciales de MongoDB
echo "admin" > secrets/backup_username
echo "tu_contraseña_aqui" > secrets/backup_password

# Host (si usas SSH: 127.0.0.1, si es local: mongodb)
echo "127.0.0.1" > secrets/backup_host

# Bases de datos a respaldar
cat > secrets/backup_databases <<EOF
database1
database2
EOF

# SSH key (opcional)
# cp ~/.ssh/id_rsa secrets/ssh_private_key

# SSL cert (opcional)
# cp /ruta/a/ca.pem secrets/backup_ca_cert
```

### 4. Ejecutar

```bash
# Iniciar servicio
docker-compose up -d

# Ver logs
docker-compose logs -f backup-mongo

# Detener
docker-compose down
```

---

## Opción 2: Clonar repositorio (con documentación)

```bash
git clone https://github.com/clopezpro/mongobackup.git
cd mongobackup

# Editar secrets con tus credenciales
nano secrets/backup_username
nano secrets/backup_password
nano secrets/backup_host
nano secrets/backup_databases

# Ejecutar
docker-compose up -d
```

---

## Configuraciones comunes 📋

### MongoDB local en Docker

```yaml
environment:
  - BACKUP_HOST=mongodb
  - BACKUP_PORT=27017
  - BACKUP_USERNAME=admin
  - BACKUP_PASSWORD=password123
```

### MongoDB remoto con SSH

```yaml
environment:
  - BACKUP_PORT=27018
  - LOCAL_PORT=27019
  - SSH_HOST=192.168.1.100
  - SSH_PORT=your_por_ssh
  - SSH_USER=mongo_backup
```

Crear clave SSH:
```bash
cp ~/.ssh/id_rsa secrets/ssh_private_key
chmod 600 secrets/ssh_private_key
```

### MongoDB con SSL/TLS

```yaml
environment:
  - BACKUP_CA_CERT_FILE=/run/secrets/backup_ca_cert
```

Copiar certificado:
```bash
cp /ruta/a/ca.pem secrets/backup_ca_cert
```

---

## Actualizar a nueva versión

```bash
# Descargar última versión
docker pull clopezpro/mongo-backup:latest

# Reiniciar servicio
docker-compose up -d --force-recreate
```

---

## Verificar estado

```bash
# Ver logs
docker-compose logs -f

# Ver backups
ls -lh backups/

# Acceder al contenedor
docker-compose exec backup-mongo sh
```

---

## Información de la imagen 🐳

```
Repository:  clopezpro/mongo-backup
Tags:        latest, 1.0
Size:        ~1.2GB (basada en mongo:latest)
Platform:    linux/amd64
Base OS:     Ubuntu (de mongo:latest)
Included:    
  - mongodump
  - cron
  - openssh-client
```

---

## Soporte y issues

Para problemas o preguntas:
- 📝 Ver documentación en README.md
- 🐛 Revisar logs con: `docker-compose logs backup-mongo`
- 💬 Contactar: [tu contacto aquí]

---

**Hecho para respaldos confiables en producción ✅**
