# 🐳 MongoDB Backup - Docker Automated Backup Service

[![Docker Hub](https://img.shields.io/badge/Docker%20Hub-clopezpro%2Fmongo--backup-blue?logo=docker)](https://hub.docker.com/r/clopezpro/mongo-backup)
[![Latest Version](https://img.shields.io/badge/Version-1.8-brightgreen)](https://hub.docker.com/r/clopezpro/mongo-backup/tags)
[![License](https://img.shields.io/badge/License-MIT-green)](#license)

Servicio Docker que realiza backups automáticos de MongoDB con:

- ✅ **Backups programados** (CRON) 
- ✅ **Túneles SSH** seguros
- ✅ **Compresión** automática (.tar.gz)
- ✅ **Limpieza automática** de backups antiguos
- ✅ **SSL/TLS** opcional para MongoDB
- ✅ **Enlaces simbólicos** a últimos backups (`*-latest.tar.gz`)
- ✅ **Manejo robusto de errores** (aborta sin perder backups anteriores)

---

## 📦 Instalación Rápida / Quick Installation

### 1. Clonar o descargar

```bash
git clone https://github.com/clopezpro/mongo-backup.git
cd mongo-backup
```

### 2. Configurar secretos

```bash
mkdir -p secrets

# Credenciales MongoDB
echo "tu_usuario" > secrets/backup_username
echo "tu_contraseña" > secrets/backup_password
echo "mongodb.host.com" > secrets/backup_host

# Bases de datos (una por línea)
echo -e "database1\ndatabase2\ndatabase3" > secrets/backup_databases

# Clave SSH (si usas túnel)
cat ~/.ssh/id_rsa > secrets/ssh_private_key
```

### 3. Configurar docker-compose

```bash
# Usar la plantilla de ejemplo
cp docker-compose.example.yml docker-compose.yml

# Editar con tus valores
nano docker-compose.yml  # Cambiar SSH_HOST, SSH_PORT, TZ, CRON_TIME
```

### 4. Iniciar

```bash
docker-compose up -d
docker-compose logs -f backup
```

### ✅ Listo!

Los backups se guardarán en `./backups/` siguiendo este patrón:
```
./backups/
├── users-latest.tar.gz              # Enlace al último backup
├── users_2026-05-22-09-47-12.tar.gz # Backup con timestamp
├── products-latest.tar.gz          # Para otra base de datos
└── products_2026-05-22-09-50-00.tar.gz
```

---

## 🎯 Características Principales / Main Features

### 🔄 Backups Automáticos
Configurable mediante CRON:
```
CRON_TIME=0 3 * * *   # 3 AM cada día
CRON_TIME=0 */6 * * * # Cada 6 horas
CRON_TIME=0 2 * * 0   # Domingos 2 AM
```

### 🔐 Seguridad SSH
- Túnel SSH automático antes del backup
- Cierre limpio del túnel después
- Soporta autenticación con clave privada

### 🗜️ Compresión
Todos los backups se comprimen automáticamente:
- `users_2026-05-22-09-47-12.tar.gz` → ~800KB (comprimido)
- Fácil descompresión: `tar -xzf backup.tar.gz`

### 🧹 Limpieza Automática
```
MAX_BACKUPS=10  # Mantiene los últimos 10, elimina antiguos
```

### 🔗 Enlaces a Últimos Backups
Accede fácilmente al backup más reciente:
```bash
# En lugar de: tar -xzf users_2026-05-22-09-47-12.tar.gz
tar -xzf ./backups/users-latest.tar.gz
```

### 🚨 Manejo de Errores
- Si MongoDB no responde: **aborta sin eliminar backups anteriores**
- Detecta errores por exit code + salida de error
- Logs detallados para debugging

---

## 📋 Uso / Usage

### Ver logs
```bash
docker-compose logs -f backup
```

### Ejecutar backup manual
```bash
docker-compose exec backup /app/backup-mongodb
```

### Descomprimir backup
```bash
tar -xzf ./backups/database-name-latest.tar.gz
```

### Restaurar base de datos
```bash
tar -xzf ./backups/database-name-latest.tar.gz
mongorestore --db database-name ./database-name/
```

### Detener servicio
```bash
docker-compose down
```

---

## 🔧 Configuración Avanzada

Ver `docker-compose.example.yml` para todas las opciones comentadas.

### Variables Principales

| Variable | Descripción | Ejemplo |
|----------|-------------|---------|
| `TZ` | Zona horaria | `America/Guayaquil` |
| `BACKUP_PORT` | Puerto MongoDB remoto | `27017` |
| `LOCAL_PORT` | Puerto local tunnel | `27019` |
| `SSH_HOST` | Servidor remoto | `your_ip_or_host` |
| `SSH_PORT` | Puerto SSH | `your_por_ssh` |
| `SSH_USER` | Usuario SSH | `mongo_backup` |
| `CRON_TIME` | Horario backup | `0 3 * * *` |
| `MAX_BACKUPS` | Máx backups guardados | `10` |
| `INIT_BACKUP` | Backup al iniciar | `1` |

---

## 📚 Documentación Completa

- 📖 [**QUICK_START.md**](./QUICK_START.md) - Guía de inicio rápido
- 📋 [**docker-compose.example.yml**](./docker-compose.example.yml) - Plantilla completamente comentada
- 🚀 [**setup.sh**](./setup.sh) - Script interactivo de configuración
- 📄 [**README_DOCKER_HUB.md**](./README_DOCKER_HUB.md) - Documentación detallada

---

## 🔒 Seguridad / Security

✅ **Prácticas recomendadas:**
- Secretos almacenados en `./secrets/` (incluido en `.gitignore`)
- Credenciales nunca exponidas en logs o variables de entorno
- Claves SSH montadas como Docker Secrets (read-only)
- `docker-compose.yml` en `.gitignore` - usa `docker-compose.example.yml` como plantilla
- Backups comprimidos con acceso controlado

⚠️ **IMPORTANTE:**
- **NO** commits `docker-compose.yml` con datos reales
- **NO** commits archivos en `./secrets/`
- **NO** expongas tu clave SSH privada

---

## 🐛 Solución de Problemas

### "Failed: error connecting to db"
Verificar credenciales y conectividad MongoDB

### "Cannot open: No such file or directory"  
Asegurar que `./backups/` existe con permisos de escritura

### SSH no funciona
Verificar que la clave privada está en `secrets/ssh_private_key`

Ver más en [**QUICK_START.md - Troubleshooting**](./QUICK_START.md#-solución-de-problemas--troubleshooting)

---

## 🐳 Imágenes Docker

| Tag | Descripción |
|-----|-------------|
| `clopezpro/mongo-backup:latest` | Última versión estable |
| `clopezpro/mongo-backup:1.8` | Versión específica |

```bash
docker pull clopezpro/mongo-backup:latest
```

---

## 📊 Ejemplo de Salida

```
✅ Túnel SSH abierto exitosamente
📦 Haciendo backup de: users
   mongodump version: 100.17.0
✅ Backup comprimido: users_2026-05-22-09-47-12.tar.gz
🔗 Enlace simbólico: users-latest.tar.gz ➜ users_2026-05-22-09-47-12.tar.gz

📦 Haciendo backup de: products
   mongodump version: 100.17.0
✅ Backup comprimido: products_2026-05-22-09-50-00.tar.gz
🔗 Enlace simbólico: products-latest.tar.gz ➜ products_2026-05-22-09-50-00.tar.gz

✅✅✅ BACKUP COMPLETADO EXITOSAMENTE ✅✅✅
🧹 Limpiando backups antiguos (máximo: 10)...
✅ Todos los backups están dentro del límite (2/10)

🔌 Cerrando túnel SSH...
✅ Túnel SSH cerrado exitosamente
```

---

## 📝 Licencia / License

MIT License - Ver [LICENSE](./LICENSE)

---

## 🤝 Contribuir / Contributing

Pull requests bienvenidos. Para cambios mayores, abre un issue primero.

---

## 📦 Stack Técnico

- **Base**: `mongo:latest` (Ubuntu + mongodump)
- **Orchestration**: Docker Compose 3.7
- **SSH**: OpenSSH Client
- **Compression**: tar + gzip
- **Scheduling**: Crond

---

## 🚀 Próximos Pasos

1. **Clonar**: `git clone <repo>`
2. **Configurar**: Editar `secrets/` y `docker-compose.yml`
3. **Iniciar**: `docker-compose up -d`
4. **Verificar**: `docker-compose logs -f backup`

---

**¡Listo! Disfruta de backups automáticos y seguros.** 🎉

For English documentation, see [README_DOCKER_HUB.md](./README_DOCKER_HUB.md)
