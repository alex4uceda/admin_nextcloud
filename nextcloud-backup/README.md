# 🔐 Nextcloud Backup Service

Servicio automatizado de backup para la infraestructura Nextcloud con conexión encriptada SSH y sincronización via RSYNC.

## 📋 Características

- **🔒 Conexión Encriptada**: Transferencias seguras via SSH/SFTP
- **📊 Backup de Base de Datos**: Respaldo completo de MySQL/MariaDB
- **📁 Sincronización de Archivos**: RSYNC incremental y completo
- **⏰ Programación Automática**: Cron jobs configurables
- **🗂️ Retención Configurable**: Limpieza automática de backups antiguos
- **✅ Verificación de Integridad**: Checksums y validación de backups
- **📝 Logging Detallado**: Monitoreo y diagnóstico completo
- **🔧 Health Checks**: Verificación automática del estado del servicio

## 🏗️ Arquitectura

```
┌─────────────────────────────────────────────────────────────┐
│                    NEXTCLOUD INFRASTRUCTURE                  │
├─────────────────┬─────────────────┬─────────────────────────┤
│   MariaDB       │   Nextcloud     │      Redis Cache        │
│   (DB Data)     │   (App + Data)  │     (Cache Data)        │
└─────────────────┴─────────────────┴─────────────────────────┘
         │                 │                      │
         └─────────────────┼──────────────────────┘
                           │
         ┌─────────────────▼─────────────────┐
         │      BACKUP SERVICE CONTAINER      │
         │                                   │
         │  🔧 rsync + mysqldump + ssh       │
         │  ⏰ cron + health checks          │
         │  📝 logging + compression         │
         └─────────────────┬─────────────────┘
                           │ SSH/RSYNC Encrypted
         ┌─────────────────▼─────────────────┐
         │       REMOTE BACKUP SERVER        │
         │                                   │
         │  📁 /backups/db/                  │
         │  📁 /backups/files/current/       │
         │  📁 /backups/files/YYYYMMDD/      │
         └───────────────────────────────────┘
```

## 🚀 Instalación Rápida

### 1. Ejecutar Script de Configuración Automática

```bash
cd /home/uceda/Documents/PROYECTO_V1
./nextcloud-backup/setup.sh
```

El script automatiza:
- ✅ Generación de llaves SSH
- ✅ Configuración de variables de entorno
- ✅ Prueba de conectividad al servidor remoto
- ✅ Construcción del contenedor Docker

### 2. Iniciar el Servicio

```bash
# Iniciar solo el servicio de backup
docker compose up -d nextcloud-backup

# O iniciar toda la infraestructura
docker compose up -d
```

## ⚙️ Configuración Manual

### 1. Configurar Servidor Remoto

En tu servidor de backup remoto:

```bash
# Crear usuario dedicado
sudo useradd -m -s /bin/bash nextcloud-backup

# Crear directorio de backups
sudo mkdir -p /home/nextcloud-backup/backups
sudo chown nextcloud-backup:nextcloud-backup /home/nextcloud-backup/backups

# Configurar SSH
sudo mkdir /home/nextcloud-backup/.ssh
sudo chmod 700 /home/nextcloud-backup/.ssh
```

### 2. Generar y Configurar Llaves SSH

```bash
# Generar llaves SSH
ssh-keygen -t rsa -b 4096 -f ./nextcloud-backup/ssh-keys/id_rsa

# Copiar llave pública al servidor remoto
ssh-copy-id -i ./nextcloud-backup/ssh-keys/id_rsa.pub nextcloud-backup@your-server.com

# Probar conexión
ssh -i ./nextcloud-backup/ssh-keys/id_rsa nextcloud-backup@your-server.com "echo 'OK'"
```

### 3. Configurar Variables de Entorno

Agrega estas variables a tu archivo `.env`:

```bash
# Configuración del servidor remoto
BACKUP_REMOTE_HOST=your-backup-server.com
BACKUP_REMOTE_USER=nextcloud-backup
BACKUP_REMOTE_PORT=22
BACKUP_REMOTE_PATH=/home/nextcloud-backup/backups

# Configuración de backup
BACKUP_RETENTION_DAYS=30
BACKUP_COMPRESSION=true
BACKUP_VERIFY_CHECKSUMS=true
BACKUP_RUN_INITIAL=false
LOG_RETENTION_DAYS=7
```

## 📅 Programación de Backups

### Horarios por Defecto

- **Backup Completo**: Diario a las 2:00 AM
- **Backup Incremental**: Cada 6 horas (6:00, 12:00, 18:00, 00:00)
- **Limpieza de Logs**: Semanal (domingos 3:00 AM)
- **Health Check**: Cada hora

### Personalizar Horarios

Edita el archivo `./nextcloud-backup/config/crontab`:

```bash
# Backup completo cada 12 horas
0 */12 * * * /app/scripts/backup-full.sh >> /app/logs/backup.log 2>&1

# Backup incremental cada 2 horas (solo días laborables)
0 */2 * * 1-5 /app/scripts/backup-incremental.sh >> /app/logs/backup.log 2>&1
```

## 🔧 Uso y Comandos

### Ejecutar Backups Manualmente

```bash
# Backup completo
docker compose exec nextcloud-backup /app/scripts/backup-full.sh

# Backup incremental
docker compose exec nextcloud-backup /app/scripts/backup-incremental.sh

# Health check
docker compose exec nextcloud-backup /app/scripts/health-check.sh
```

### Monitoreo y Logs

```bash
# Ver logs en tiempo real
docker compose logs -f nextcloud-backup

# Ver logs específicos
docker compose exec nextcloud-backup tail -f /app/logs/backup.log
docker compose exec nextcloud-backup tail -f /app/logs/error.log
docker compose exec nextcloud-backup tail -f /app/logs/health.log

# Estado del servicio
docker compose ps nextcloud-backup
```

### Gestión del Contenedor

```bash
# Reiniciar servicio
docker compose restart nextcloud-backup

# Reconstruir contenedor
docker compose build nextcloud-backup
docker compose up -d nextcloud-backup

# Acceder al contenedor
docker compose exec nextcloud-backup /bin/bash
```

## 📂 Estructura de Backups

### Servidor Remoto

```
/home/nextcloud-backup/backups/
├── db/                           # Backups de base de datos
│   ├── nextcloud_db_20241101_020000.sql.gz
│   ├── nextcloud_db_20241101_020000.sql.gz.md5
│   └── nextcloud_db_20241102_020000.sql.gz
├── files/                        # Backups de archivos
│   ├── current/                  # Sincronización incremental actual
│   │   ├── nextcloud/
│   │   ├── nextcloud_data/
│   │   └── redis/
│   ├── 20241101_020000/          # Snapshot completo
│   │   ├── nextcloud/
│   │   ├── nextcloud_data/
│   │   ├── redis/
│   │   └── backup_metadata.json
│   └── incremental_20241101_080000/ # Cambios incrementales
└── *.json                        # Metadatos de backups incrementales
```

### Local (Temporal)

```
./nextcloud-backup/
├── logs/                         # Logs del servicio
│   ├── backup.log
│   ├── error.log
│   └── health.log
├── ssh-keys/                     # Llaves SSH
│   ├── id_rsa
│   └── id_rsa.pub
└── config/                       # Configuración
    ├── crontab
    └── backup.conf
```

## 🔍 Troubleshooting

### Problemas Comunes

**❌ Error de conexión SSH:**
```bash
# Verificar conectividad
ssh -i ./nextcloud-backup/ssh-keys/id_rsa user@server "echo OK"

# Verificar permisos
ls -la ./nextcloud-backup/ssh-keys/
```

**❌ Error de permisos en servidor remoto:**
```bash
# En el servidor remoto
sudo chown -R nextcloud-backup:nextcloud-backup /home/nextcloud-backup/
sudo chmod 755 /home/nextcloud-backup/.ssh
sudo chmod 600 /home/nextcloud-backup/.ssh/authorized_keys
```

**❌ Error de base de datos:**
```bash
# Verificar conectividad a MySQL
docker compose exec nextcloud-backup nc -z db 3306

# Verificar credenciales
docker compose exec nextcloud-backup mysql -h db -u $MYSQL_USER -p$MYSQL_PASSWORD -e "SHOW DATABASES;"
```

**❌ Espacio insuficiente:**
```bash
# Verificar espacio local
df -h ./

# Verificar espacio remoto
ssh user@server "df -h /home/nextcloud-backup/"

# Limpiar backups antiguos manualmente
docker compose exec nextcloud-backup /app/scripts/cleanup-logs.sh
```

### Logs de Diagnóstico

```bash
# Debug completo
docker compose exec nextcloud-backup /bin/bash -c "
echo '=== CONFIGURACIÓN ==='
env | grep BACKUP_
echo '=== CONECTIVIDAD ==='
nc -z db 3306 && echo 'DB OK' || echo 'DB ERROR'
echo '=== SSH ==='
ssh -o ConnectTimeout=5 \$BACKUP_REMOTE_USER@\$BACKUP_REMOTE_HOST 'echo SSH_OK' 2>&1
echo '=== ESPACIO ==='
df -h /backups
"
```

## 🔧 Configuración Avanzada

### Variables de Entorno Adicionales

```bash
# Performance
RSYNC_BANDWIDTH_LIMIT=1000        # KB/s
PARALLEL_COMPRESSION=true
COMPRESSION_LEVEL=6               # 1-9

# Seguridad
SSH_CONNECTION_TIMEOUT=30
VERIFY_BACKUP_INTEGRITY=true
VERIFY_REMOTE_CHECKSUMS=true

# Notificaciones
NOTIFICATIONS_ENABLED=false
NOTIFICATION_EMAIL=admin@example.com
NOTIFICATION_ON_ERROR=true
```

### Personalizar Scripts

Los scripts están en `./nextcloud-backup/scripts/` y pueden modificarse según necesidades específicas:

- `backup-full.sh` - Backup completo
- `backup-incremental.sh` - Backup incremental
- `health-check.sh` - Verificaciones de salud
- `cleanup-logs.sh` - Limpieza de logs

## 📊 Monitoreo y Alertas

### Health Checks HTTP (Opcional)

Si habilitas el puerto 8080, puedes acceder a:

```bash
# Status endpoint
curl http://localhost:8080/health

# Metrics endpoint
curl http://localhost:8080/metrics
```

### Integración con Monitoring

El servicio genera logs en formato estructurado compatible con:
- **Prometheus** (métricas)
- **Grafana** (dashboards)
- **ELK Stack** (análisis de logs)

## 🚨 Seguridad

### Mejores Prácticas

✅ **Usar llaves SSH dedicadas** (no reutilizar llaves personales)
✅ **Configurar usuario dedicado** en servidor remoto
✅ **Restringir permisos SSH** (solo backup, no shell interactivo)
✅ **Encriptar backups** en tránsito (SSH) y reposo (opcional)
✅ **Monitorear accesos** SSH en servidor remoto
✅ **Rotar llaves SSH** periódicamente

### Configuración SSH Restrictiva

En el servidor remoto (`/home/nextcloud-backup/.ssh/authorized_keys`):

```bash
command="/usr/bin/rsync --server",no-port-forwarding,no-X11-forwarding,no-agent-forwarding ssh-rsa AAAAB3...
```

## 🔄 Restauración de Backups

### Restaurar Base de Datos

```bash
# Descomprimir backup
gunzip nextcloud_db_YYYYMMDD_HHMMSS.sql.gz

# Restaurar a la base de datos
mysql -h db -u $MYSQL_USER -p$MYSQL_PASSWORD $MYSQL_DATABASE < nextcloud_db_YYYYMMDD_HHMMSS.sql
```

### Restaurar Archivos

```bash
# Sincronizar desde backup completo
rsync -av user@server:/path/to/backup/files/YYYYMMDD_HHMMSS/ ./restore/

# Restaurar a Nextcloud
cp -r ./restore/nextcloud/* ./nextcloud/
cp -r ./restore/nextcloud_data/* ./nextcloud_data/
```

## 📞 Soporte

Para problemas o mejoras:

1. Verificar logs: `/app/logs/`
2. Ejecutar health check: `/app/scripts/health-check.sh`
3. Revisar configuración de red y SSH
4. Consultar documentación de troubleshooting

---

**🔐 Nextcloud Backup Service** - Respaldo seguro y automatizado para tu infraestructura Nextcloud.