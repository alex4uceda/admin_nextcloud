#!/bin/bash
# ===================================================================================
# NEXTCLOUD BACKUP - HEALTH CHECK
# ===================================================================================

set -euo pipefail

# Configuración
HEALTH_LOG="/app/logs/health.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Función de logging
log_health() {
    echo "[$TIMESTAMP] [HEALTH] $1" | tee -a "$HEALTH_LOG"
}

# Función principal de health check
main() {
    local exit_code=0
    
    log_health "Iniciando health check..."
    
    # 1. Verificar que los logs existen y son escribibles
    if ! touch /app/logs/test_write 2>/dev/null; then
        log_health "ERROR: No se puede escribir en directorio de logs"
        exit_code=1
    else
        rm -f /app/logs/test_write
        log_health "✓ Directorio de logs accesible"
    fi
    
    # 2. Verificar conectividad a la base de datos
    if [ -n "${BACKUP_DB_HOST:-}" ]; then
        if nc -z "$BACKUP_DB_HOST" "${BACKUP_DB_PORT:-3306}" 2>/dev/null; then
            log_health "✓ Conectividad a base de datos OK"
        else
            log_health "ERROR: No se puede conectar a la base de datos"
            exit_code=1
        fi
    fi
    
    # 3. Verificar conectividad SSH al servidor remoto
    if [ -n "${BACKUP_REMOTE_HOST:-}" ] && [ -n "${BACKUP_REMOTE_USER:-}" ]; then
        if ssh -o ConnectTimeout=10 -o BatchMode=yes \
           "$BACKUP_REMOTE_USER@$BACKUP_REMOTE_HOST" "echo 'OK'" >/dev/null 2>&1; then
            log_health "✓ Conectividad SSH al servidor remoto OK"
        else
            log_health "WARN: No se puede conectar al servidor remoto (SSH)"
            # No es crítico para el health check
        fi
    fi
    
    # 4. Verificar que cron está ejecutándose
    if pgrep crond >/dev/null; then
        log_health "✓ Servicio cron ejecutándose"
    else
        log_health "ERROR: Servicio cron no está ejecutándose"
        exit_code=1
    fi
    
    # 5. Verificar espacio en disco local
    local disk_usage
    disk_usage=$(df /backups | tail -1 | awk '{print $5}' | sed 's/%//')
    if [ "$disk_usage" -lt 90 ]; then
        log_health "✓ Espacio en disco OK ($disk_usage% usado)"
    else
        log_health "WARN: Poco espacio en disco ($disk_usage% usado)"
    fi
    
    # 6. Verificar archivos de configuración SSH
    if [ -f "/home/backup/.ssh/id_rsa" ]; then
        log_health "✓ Llaves SSH configuradas"
    else
        log_health "WARN: No se encontraron llaves SSH"
    fi
    
    # Resultado final
    if [ $exit_code -eq 0 ]; then
        log_health "✓ Health check PASSED - Servicio saludable"
    else
        log_health "✗ Health check FAILED - Se detectaron problemas"
    fi
    
    exit $exit_code
}

# Ejecutar health check
main "$@"