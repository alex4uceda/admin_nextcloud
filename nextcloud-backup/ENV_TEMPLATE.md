# ===================================================================================
# NEXTCLOUD BACKUP SERVICE - VARIABLES DE ENTORNO
# ===================================================================================
# 
# Copia estas variables a tu archivo .env principal y configura los valores
# según tu servidor remoto de backups
# ===================================================================================

# ==============================
# CONFIGURACIÓN DEL SERVIDOR REMOTO DE BACKUP
# ==============================
# REQUERIDO: Configura estos valores para tu servidor de backup

# Dirección IP o hostname del servidor remoto
BACKUP_REMOTE_HOST=your-backup-server.com

# Usuario SSH en el servidor remoto
BACKUP_REMOTE_USER=backup-user

# Puerto SSH del servidor remoto (por defecto 22)
BACKUP_REMOTE_PORT=22

# Ruta en el servidor remoto donde se almacenarán los backups
BACKUP_REMOTE_PATH=/path/to/backup/storage/nextcloud

# ==============================
# CONFIGURACIÓN DE BACKUP
# ==============================
# OPCIONAL: Personaliza el comportamiento del backup

# Días de retención de backups (por defecto 30)
BACKUP_RETENTION_DAYS=30

# Habilitar compresión de backups (true/false)
BACKUP_COMPRESSION=true

# Verificar checksums de archivos (true/false)
BACKUP_VERIFY_CHECKSUMS=true

# Ejecutar backup inicial al iniciar servicio (true/false)
BACKUP_RUN_INITIAL=false

# Días de retención de logs (por defecto 7)
LOG_RETENTION_DAYS=7

# ===================================================================================
# INSTRUCCIONES DE CONFIGURACIÓN
# ===================================================================================
# 
# 1. CONFIGURAR SERVIDOR REMOTO:
#    - Crea un usuario dedicado para backups en tu servidor remoto
#    - Configura acceso SSH sin contraseña usando llaves públicas/privadas
#    - Asegúrate de que el usuario tenga permisos de escritura en BACKUP_REMOTE_PATH
# 
# 2. GENERAR LLAVES SSH:
#    - Ejecuta: ssh-keygen -t rsa -b 4096 -f ./nextcloud-backup/ssh-keys/id_rsa
#    - Copia el contenido de id_rsa.pub al archivo ~/.ssh/authorized_keys del servidor remoto
# 
# 3. PROBAR CONECTIVIDAD:
#    - Ejecuta: ssh -i ./nextcloud-backup/ssh-keys/id_rsa user@server "echo 'OK'"
#    - Debe mostrar "OK" sin solicitar contraseña
# 
# 4. CREAR DIRECTORIO REMOTO:
#    - Asegúrate de que existe: ssh user@server "mkdir -p /path/to/backup/storage/nextcloud"
# 
# ===================================================================================
# EJEMPLO DE CONFIGURACIÓN COMPLETA
# ===================================================================================
# 
# BACKUP_REMOTE_HOST=192.168.1.100
# BACKUP_REMOTE_USER=nextcloud-backup
# BACKUP_REMOTE_PORT=22
# BACKUP_REMOTE_PATH=/home/nextcloud-backup/backups
# BACKUP_RETENTION_DAYS=45
# BACKUP_COMPRESSION=true
# BACKUP_VERIFY_CHECKSUMS=true
# BACKUP_RUN_INITIAL=false
# LOG_RETENTION_DAYS=14
# 
# ===================================================================================