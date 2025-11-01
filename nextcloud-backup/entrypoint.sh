#!/bin/bash
# ===================================================================================
# NEXTCLOUD BACKUP SERVICE - ENTRYPOINT
# ===================================================================================

set -e

# Función de logging
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ENTRYPOINT] $1"
}

# Función para configurar SSH
setup_ssh() {
    log "Configurando acceso SSH..."
    
    # Verificar si existen llaves SSH montadas desde el host
    if [ -f "/app/config/ssh-keys/id_rsa" ]; then
        log "Usando llaves SSH maestras del host..."
        cp /app/config/ssh-keys/id_rsa /home/backup/.ssh/
        cp /app/config/ssh-keys/id_rsa.pub /home/backup/.ssh/
        chmod 600 /home/backup/.ssh/id_rsa
        chmod 644 /home/backup/.ssh/id_rsa.pub
        log "Llaves SSH maestras configuradas correctamente"
        
        # Mostrar información de la llave para verificación
        log "Huella digital de la llave SSH:"
        ssh-keygen -lf /home/backup/.ssh/id_rsa.pub 2>/dev/null || log "No se pudo obtener huella digital"
        
    else
        log "ADVERTENCIA: No se encontraron llaves SSH maestras en /app/config/ssh-keys/"
        log "Verificando si hay llaves SSH generadas previamente..."
        
        if [ ! -f "/home/backup/.ssh/id_rsa" ]; then
            log "Generando llaves SSH temporales para este contenedor..."
            ssh-keygen -t rsa -b 4096 -f /home/backup/.ssh/id_rsa -N "" -q
            log "Llaves SSH temporales generadas."
            log "IMPORTANTE: Para automatización completa, usa el script setup-complete-backup.sh"
        else
            log "Usando llaves SSH existentes del contenedor"
        fi
        
        log "Llave pública actual:"
        cat /home/backup/.ssh/id_rsa.pub
    fi
    
    # Verificar permisos finales
    chmod 700 /home/backup/.ssh
    chmod 600 /home/backup/.ssh/id_rsa 2>/dev/null || true
    chmod 644 /home/backup/.ssh/id_rsa.pub 2>/dev/null || true
}

# Función para configurar crontab personalizado
setup_crontab() {
    log "Configurando tareas programadas..."
    
    # Asegurar que el directorio de crontab existe con permisos correctos
    mkdir -p /var/spool/cron/crontabs
    chown -R backup:backup /var/spool/cron/crontabs
    
    # Si existe configuración personalizada de cron, usarla
    if [ -f "/app/config/crontab" ]; then
        cp /app/config/crontab /var/spool/cron/crontabs/backup
        chown backup:backup /var/spool/cron/crontabs/backup
        chmod 600 /var/spool/cron/crontabs/backup
        log "Crontab personalizado configurado"
    else
        log "Usando configuración de crontab por defecto"
        chown backup:backup /var/spool/cron/crontabs/backup 2>/dev/null || true
        chmod 600 /var/spool/cron/crontabs/backup 2>/dev/null || true
    fi
    
    # Mostrar tareas programadas
    log "Tareas programadas activas:"
    su backup -c "crontab -l" 2>/dev/null | grep -v '^#' | grep -v '^$' || log "No hay tareas programadas"
}

# Función para verificar conectividad
check_connectivity() {
    log "Verificando conectividad..."
    
    # Verificar conexión a la base de datos
    if [ -n "$BACKUP_DB_HOST" ]; then
        log "Verificando conexión a base de datos: $BACKUP_DB_HOST:$BACKUP_DB_PORT"
        if nc -z "$BACKUP_DB_HOST" "${BACKUP_DB_PORT:-3306}"; then
            log "✓ Conexión a base de datos exitosa"
        else
            log "✗ No se pudo conectar a la base de datos"
        fi
    fi
    
    # Verificar servidor remoto de backup
    if [ -n "$BACKUP_REMOTE_HOST" ] && [ -n "$BACKUP_REMOTE_USER" ]; then
        log "Verificando conexión SSH a servidor remoto: $BACKUP_REMOTE_USER@$BACKUP_REMOTE_HOST"
        if ssh -o ConnectTimeout=10 -o BatchMode=yes "$BACKUP_REMOTE_USER@$BACKUP_REMOTE_HOST" "echo 'SSH OK'" 2>/dev/null; then
            log "✓ Conexión SSH al servidor remoto exitosa"
        else
            log "✗ No se pudo conectar al servidor remoto via SSH"
            log "NOTA: Asegúrate de que la llave pública esté configurada en el servidor remoto"
        fi
    fi
}

# Función para crear directorios necesarios
create_directories() {
    log "Creando directorios de trabajo..."
    
    mkdir -p /app/logs
    mkdir -p /backups/local/db
    mkdir -p /backups/local/files
    
    # Crear archivo de log si no existe
    touch /app/logs/backup.log
    touch /app/logs/error.log
    
    log "Directorios creados correctamente"
}

# Función para mostrar configuración
show_config() {
    log "=== CONFIGURACIÓN DEL SERVICIO DE BACKUP ==="
    log "Base de datos: ${BACKUP_DB_HOST:-'No configurada'}:${BACKUP_DB_PORT:-3306}"
    log "Usuario DB: ${BACKUP_DB_USER:-'No configurado'}"
    log "Servidor remoto: ${BACKUP_REMOTE_USER:-'No configurado'}@${BACKUP_REMOTE_HOST:-'No configurado'}"
    log "Directorio remoto: ${BACKUP_REMOTE_PATH:-'No configurado'}"
    log "Retención: ${BACKUP_RETENTION_DAYS:-30} días"
    log "Compresión: ${BACKUP_COMPRESSION:-true}"
    log "Verificación: ${BACKUP_VERIFY_CHECKSUMS:-true}"
    log "Zona horaria: ${TZ:-UTC}"
    log "=============================================="
}

# Función principal
main() {
    log "Iniciando servicio de backup de Nextcloud..."
    
    # Configurar componentes
    setup_ssh
    create_directories
    setup_crontab
    show_config
    check_connectivity
    
    # Ejecutar backup inicial si se solicita
    if [ "$BACKUP_RUN_INITIAL" = "true" ]; then
        log "Ejecutando backup inicial..."
        /app/scripts/backup-full.sh
    fi
    
    log "Servicio de backup configurado correctamente"
    
    # Iniciar cron daemon
    /usr/sbin/crond -f -l 2 &
    CRON_PID=$!
    
    log "Servicio cron iniciado con PID: $CRON_PID"
    log "Servicio de backup ejecutándose. Para detener, usa: docker stop nextcloud-backup"
    
    # Mantener el contenedor activo
    wait $CRON_PID
}

# Manejo de señales para shutdown graceful
trap 'log "Recibida señal de terminación, cerrando servicio..."; exit 0' SIGTERM SIGINT

# Ejecutar función principal
main "$@"