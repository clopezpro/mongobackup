# MongoDB Backup en Docker 🐳

**Respaldos automáticos de MongoDB con túnel SSH, SSL/TLS opcional, compresión .tar.gz y limpieza automática.**

![Docker Hub](https://img.shields.io/badge/Docker%20Hub-mongo--backup-blue?logo=docker)
![License](https://img.shields.io/badge/License-MIT-green)

## Características principales ✨

- ✅ **Respaldos automáticos** - Ejecuta mongodump con cron programable
- ✅ **Túnel SSH automático** - Abre y cierra túneles SSH antes/después del backup
- ✅ **SSL/TLS opcional** - Detecta certificado y lo usa automáticamente
- ✅ **Compresión .tar.gz** - Comprime todos los backups para ahorrar espacio
- ✅ **Zona horaria configurable** - Usa TZ correctamente en cron y nombres de archivo
- ✅ **Múltiples bases de datos** - Respalda múltiples DBs en una sola ejecución
- ✅ **Limpieza automática** - Elimina backups antiguos manteniendo límite configurable
- ✅ **Manejo de errores robusto** - Si falla conexión, aborta sin eliminar backups previos
- ✅ **Docker Secrets** - Credenciales protegidas (no en variables de entorno)
- ✅ **Sin dependencias externas** - Basado en imagen oficial `mongo:latest`

## Uso rápido 🚀

### 1. Crear directorio de secretos

```bash
mkdir -p mongobackup/secrets
cd mongobackup
```

### 2. Crear archivo `docker-compose.yml`

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
  backup:
    image: clopezpro/mongo-backup
    container_name: mongodb-backup
    volumes:
      - ./backups:/backups
    environment:
      # Zona horaria (importante para cron y nombres de archivo)
      - TZ=America/Guayaquil
      
      # Configuración de MongoDB (puerto del servidor remoto)
      - BACKUP_PORT=27018
      - LOCAL_PORT=27019
      - BACKUP_HOST_FILE=/run/secrets/backup_host
      - BACKUP_USERNAME_FILE=/run/secrets/backup_username
      - BACKUP_PASSWORD_FILE=/run/secrets/backup_password
      - BACKUP_DATABASES_FILE=/run/secrets/backup_databases
      - BACKUP_AUTHENTICATIONDATABASE=admin
      - BACKUP_CA_CERT_FILE=/run/secrets/backup_ca_cert
      
      # Configuración de túnel SSH (si MongoDB está en servidor remoto)
      - SSH_PRIVATE_KEY_FILE=/run/secrets/ssh_private_key
      - SSH_USER=mongo_backup
      - SSH_HOST=your_ip_or_host
      - SSH_PORT=your_por_ssh
      
      # Configuración del backup
      - CRON_TIME=0 3 * * *           # Diariamente a las 3 AM UTC
      - MAX_BACKUPS=10                # Mantener últimos 10 respaldos
      - INIT_BACKUP=1                 # Ejecutar backup al iniciar (para pruebas)
    
    secrets:
      - backup_username
      - backup_password
      - backup_host
      - backup_databases
      - ssh_private_key
      - backup_ca_cert
    
    restart: unless-stopped
```

### 3. Crear archivos de secretos

```bash
# Usuario y contraseña de MongoDB
echo "admin" > secrets/backup_username
echo "mi_contraseña_segura" > secrets/backup_password

# Host donde corre MongoDB (si usas SSH: 127.0.0.1, si es local: mongodb)
echo "127.0.0.1" > secrets/backup_host

# Bases de datos a respaldar (una por línea)
cat > secrets/backup_databases <<EOF
users
products
myapp_db
EOF

# Clave SSH privada (OPCIONAL - solo si necesitas túnel SSH)
cp ~/.ssh/id_rsa secrets/ssh_private_key
chmod 600 secrets/ssh_private_key

# Certificado SSL/TLS (OPCIONAL - solo si MongoDB requiere SSL)
# cp /ruta/a/ca.pem secrets/backup_ca_cert
```

### 4. Ejecutar

```bash
docker-compose up -d

# Ver logs
docker-compose logs -f backup
```

## Configuración detallada 📋

### Variables de entorno

| Variable | Descripción | Ejemplo | Por defecto |
|----------|-------------|---------|------------|
| `TZ` | Zona horaria | `America/Guayaquil` | `UTC` |
| `BACKUP_PORT` | Puerto de MongoDB | `27018` | `27017` |
| `LOCAL_PORT` | Puerto local para túnel SSH | `27019` | `27019` |
| `BACKUP_AUTHENTICATIONDATABASE` | DB para autenticar | `admin` | `admin` |
| `SSH_PORT` | Puerto SSH del servidor | `your_por_ssh` | `22` |
| `SSH_USER` | Usuario SSH | `mongo_backup` | `admin` |
| `SSH_HOST` | IP pública del servidor | `your_ip_or_host` | (requerido si usas SSH) |
| `CRON_TIME` | Horario de cron | `0 3 * * *` | `0 3 * * *` |
| `MAX_BACKUPS` | Máximo de backups a mantener | `10` | `0` (ilimitado) |
| `INIT_BACKUP` | Ejecutar backup al iniciar | `1` | `0` |

### Archivos de secretos (Docker Secrets)

| Archivo | Descripción | Ejemplo |
|---------|-------------|---------|
| `backup_username` | Usuario MongoDB | `admin` |
| `backup_password` | Contraseña MongoDB | `mi_contraseña` |
| `backup_host` | Host de MongoDB | `127.0.0.1` ó `mongodb` |
| `backup_databases` | Lista de DBs (una por línea) | `users\nproducts` |
| `ssh_private_key` | Clave SSH (OPCIONAL) | Contenido de `id_rsa` |
| `backup_ca_cert` | Certificado CA SSL (OPCIONAL) | Contenido de `ca.pem` |

## Ejemplos de uso 📝

### Ejemplo 1: MongoDB local en Docker

```yaml
environment:
  - BACKUP_HOST_FILE=/run/secrets/backup_host
  - BACKUP_PORT=27017
```

`secrets/backup_host`:
```
mongodb
```

### Ejemplo 2: MongoDB remoto con SSH y SSL

```yaml
environment:
  - BACKUP_PORT=27018
  - LOCAL_PORT=27019
  - SSH_HOST=192.168.1.100
  - SSH_PORT=your_por_ssh
  - SSH_USER=mongo_backup
```

`secrets/backup_host`:
```
127.0.0.1
```

Copia tu certificado SSL:
```bash
cp /ruta/a/ca.crt secrets/backup_ca_cert
```

### Ejemplo 3: Múltiples bases de datos

`secrets/backup_databases`:
```
database1
database2
database3
production_db
```

Cada base de datos se respalda en archivos separados:
```
backups/
├── database1_2026-05-21-03-00-00.tar.gz
├── database2_2026-05-21-03-00-00.tar.gz
├── database3_2026-05-21-03-00-00.tar.gz
└── production_db_2026-05-21-03-00-00.tar.gz
```

## Horarios de cron 🕐

Ejemplos de `CRON_TIME`:

| Expresión | Horario |
|-----------|---------|
| `0 3 * * *` | Cada día a las 3 AM UTC |
| `0 2 * * 0` | Cada domingo a las 2 AM UTC |
| `0 */6 * * *` | Cada 6 horas |
| `30 1 * * *` | Cada día a la 1:30 AM UTC |
| `0 0 * * 1-5` | Lunes a viernes a medianoche |

## Monitoreo 📊

### Ver logs en tiempo real

```bash
docker-compose logs -f backup
```

### Ver último backup

```bash
ls -lh backups/ | tail -1
```

### Ver tamaño de respaldos

```bash
du -sh backups/*
```

### Verificar que cron está corriendo

```bash
docker exec mongodb-backup ps aux | grep cron
```

## Troubleshooting 🔧

### Error: "Failed: can't create session: failed to connect"

**Causas posibles:**
1. Credenciales incorrectas en `backup_username` o `backup_password`
2. Host o puerto incorrectos en `backup_host` o `BACKUP_PORT`
3. MongoDB no disponible o con firewall
4. SSH no conecta (verifica `SSH_HOST`, `SSH_PORT`, clave SSH)

**Solución:**
```bash
# Prueba conectividad
docker exec mongodb-backup sh -c 'nc -zv 127.0.0.1 27019'

# Ver logs detallados
docker-compose logs backup | grep -A5 "ERROR CRÍTICO"
```

### Error: "unknown option \`tls\`"

La imagen usa `--ssl` (no `--tls`) por compatibilidad con mongodump v100+. Esto es automático.

### SSH no conecta

Verifica la clave SSH:
```bash
# La clave debe ser válida
head -1 secrets/ssh_private_key
# Debe mostrar: -----BEGIN RSA PRIVATE KEY-----

# Permisos correctos
ls -la secrets/ssh_private_key
# Debe ser: -rw------- (600)
```

### Backups no se comprimen

Esto ocurre solo si hay error de conexión MongoDB. Los backups parciales se comprimen así.

## Estructura de archivos 📁

```
mongobackup/
├── docker-compose.yml
├── secrets/
│   ├── backup_username
│   ├── backup_password
│   ├── backup_host
│   ├── backup_databases
│   ├── ssh_private_key (opcional)
│   └── backup_ca_cert (opcional)
├── backups/
│   ├── users_2026-05-21-17-10-18.tar.gz
│   └── products_2026-05-21-17-10-29.tar.gz
└── .gitignore (con secrets/ y backups/)
```

## Logs de ejemplo ✅

Backup exitoso:
```
✅ Cron configurado: 0 3 * * *
📁 Directorio de backups: /backups
🚀 Ejecutando backup inicial...
✅ Certificado SSL/TLS detectado, habilitando...
🔐 Abriendo túnel SSH...
✅ Túnel SSH abierto exitosamente
📦 Haciendo backup de: users
   🔧 Conectando a: 127.0.0.1:27019 → base de datos: users
   🔒 Opciones SSL: --ssl --sslCAFile=/run/secrets/backup_ca_cert
📦 Comprimiendo backup: users_2026-05-21-17-10-18.tar.gz
✅ Backup comprimido: users_2026-05-21-17-10-18.tar.gz
✅✅✅ BACKUP COMPLETADO EXITOSAMENTE ✅✅✅
🧹 Limpiando backups antiguos (máximo: 10)...
✅ Todos los backups están dentro del límite (2/10)
🔌 Cerrando túnel SSH...
```

## Recuperar backups 🔄

```bash
# Extraer backup completo
cd backups
tar -xzf users_2026-05-21-17-10-18.tar.gz

# Restaurar a MongoDB
mongorestore \
  --username=admin \
  --password=tu_contraseña \
  --host=localhost:27017 \
  --authenticationDatabase=admin \
  ./users_2026-05-21-17-10-18/
```

## Licencia 📜

MIT License - Libre para usar en producción

## Soporte 💬

- Documentación completa: Ver `README.md` en repositorio
- Issues: GitHub (si aplica)
- Pull requests: Bienvenidos

---

**Hecho con ❤️ para respaldos automáticos confiables**
