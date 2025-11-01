#!/bin/bash
# ===================================================================================
# NEXTCLOUD BACKUP - LIMPIEZA DE LOGS
# ===================================================================================

set -euo pipefail

SCRIPT_NAME="cleanup-logs"
LOG_FILE="/app/logs/backup.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Función de logging
log() {
    echo "[$TIMESTAMP] [$SCRIPT_NAME] $1" | tee -a "$LOG_FILE"
}

# Función principal
main() {
    log "Iniciando limpieza de logs..."
    
    local log_retention_days="${LOG_RETENTION_DAYS:-7}"
    local logs_cleaned=0
    
    # Limpiar logs antiguos
    if find /app/logs -name "*.log" -mtime +$log_retention_days -type f -delete 2>/dev/null; then
        logs_cleaned=$((logs_cleaned + 1))
    fi
    
    # Limpiar metadatos antiguos
    find /app/logs -name "*_metadata_*.json" -mtime +$log_retention_days -delete 2>/dev/null || true
    
    # Rotar log principal si es muy grande (>50MB)
    if [ -f "$LOG_FILE" ]; then
        local log_size
        log_size=$(stat -c%s "$LOG_FILE" 2>/dev/null || echo 0)
        if [ "$log_size" -gt 52428800 ]; then  # 50MB
            mv "$LOG_FILE" "$LOG_FILE.old"
            touch "$LOG_FILE"
            log "Log principal rotado (tamaño: $log_size bytes)"
        fi
    fi
    
    # Comprimir logs antiguos
    find /app/logs -name "*.log.old" -exec gzip {} \; 2>/dev/null || true
    
    log "Limpieza completada (retención: $log_retention_days días)"
}

main "$@"