# Ejemplo de estructura de secretos
# Example secrets structure
#
# Copiar este directorio como referencia:
# Copy this directory as reference:
#
# mkdir -p secrets
# echo "backup_user" > secrets/backup_username
# echo "secure_password_123" > secrets/backup_password
# echo "mongodb.example.com" > secrets/backup_host
# echo "database1
# database2" > secrets/backup_databases
# cat ~/.ssh/id_rsa > secrets/ssh_private_key
# cat /path/to/ca-cert.pem > secrets/backup_ca_cert  # [OPCIONAL / OPTIONAL]
#
# IMPORTANTE: Asegúrate de que los archivos NO tengan saltos de línea al final
# IMPORTANT: Ensure files do NOT have trailing newlines
#
# Verificar contenido / Verify content:
# cat secrets/backup_username  # Debe mostrar solo: backup_user
