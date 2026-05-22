# Docker Secrets - Ejemplo

Este directorio contiene los archivos de secrets que Docker Compose usa para pasar credenciales de forma segura.

## Crear los archivos de secrets

Crea los siguientes archivos en este directorio:

### 1. backup_username
```bash
echo "admin" > secrets/backup_username
```

### 2. backup_password
```bash
echo "tu_contraseña_aqui" > secrets/backup_password
```

### 3. backup_host
```bash
# Si usas el contenedor MongoDB interno (recomendado)
echo "mongodb" > secrets/backup_host

# O si conectas a un MongoDB externo
echo "mongo.example.com" > secrets/backup_host
```

### 4. backup_databases
Lista de bases de datos a respaldar (una por línea):

```bash
# Crear archivo con bases de datos (una por línea)
cat > secrets/backup_databases <<EOF
users
products
myapp_db
EOF

# O si ya existe el archivo, simplemente editarlo
nano secrets/backup_databases
```

**Formato importante:**
- Una base de datos por línea
- Sin espacios ni comas
- Las líneas vacías se ignoran automáticamente

### 5. ssh_private_key (Opcional)
Solo si necesitas túnel SSH:

```bash
# ⚠️ IMPORTANTE: La clave SSH se debe guardar SIN codificar en base64
# Simplemente copia tu clave SSH privada tal cual

cp ~/.ssh/id_rsa secrets/ssh_private_key

# Asegurate que tenga permisos correctos
chmod 600 secrets/ssh_private_key

# Verificar que sea una clave válida
head -1 secrets/ssh_private_key
# Debería mostrar: -----BEGIN RSA PRIVATE KEY-----
```

### 6. backup_ca_cert (Opcional - Solo si MongoDB requiere TLS/SSL)
Solo si tu MongoDB requiere certificado SSL/TLS:

```bash
# Copiar el certificado CA (Certificate Authority)
cp /ruta/a/tu/ca.pem secrets/backup_ca_cert

# O si tienes certificado en formato .crt
cp /ruta/a/tu/ca.crt secrets/backup_ca_cert

# Asegurar permisos correctos
chmod 444 secrets/backup_ca_cert

# Verificar que sea un certificado válido
head -1 secrets/backup_ca_cert
# Debería mostrar: -----BEGIN CERTIFICATE-----
```

**Notas sobre TLS/SSL:**
- Si el archivo `backup_ca_cert` NO existe, se conectará SIN encriptación
- Si el archivo existe, automáticamente se habilitará `--tls --tlsCAFile`
- Útil si tu MongoDB está configurado con TLS/SSL obligatorio

## Estructura final esperada

```
mongobackup/
├── secrets/
│   ├── backup_username
│   ├── backup_password
│   ├── backup_host
│   ├── backup_databases
│   └── ssh_private_key (opcional)
├── backups/
├── docker-compose.yml
├── Dockerfile
├── backup.sh
└── entrypoint.sh
```

## Variables de entorno

Puedes configurar en el `docker-compose.yml`:

- `BACKUP_PORT`: Puerto de MongoDB (default: 27017)
- `BACKUP_AUTHENTICATIONDATABASE`: Database para autenticar (default: admin)
- `SSH_PORT`: Puerto SSH si usas túnel (default: 22)
- `SSH_USER`: Usuario SSH si usas túnel (default: admin)
- `CRON_TIME`: Horario del backup (default: 0 3 * * *) - cada día a las 3 AM
- `MAX_BACKUPS`: Número máximo de backups a mantener (default: 0 = ilimitado)
- `INIT_BACKUP`: Ejecutar backup al iniciar contenedor (default: 0)
- `TZ`: Zona horaria para el cron (default: UTC)

Ejemplo cron times:
- `0 3 * * *` - Cada día a las 3 AM
- `0 2 * * 0` - Cada domingo a las 2 AM
- `0 */6 * * *` - Cada 6 horas
- `0 0 * * *` - Cada media noche
