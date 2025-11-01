#!/bin/bash
# ===================================================================================
# NEXTCLOUD BACKUP - BACKUP INCREMENTAL
# ===================================================================================
# 
# FUNCIONALIDAD:
# - Backup incremental de archivos modificados via RSYNC
# - Sincronización eficiente solo de cambios
# - Transferencia encriptada al servidor remoto
# - Menor uso de ancho de banda y almacenamiento
# ===================================================================================

set -euo pipefail

# Configuración de logging
SCRIPT_NAME="backup-incremental"
LOG_FILE="/app/logs/backup.log"
ERROR_LOG="/app/logs/error.log"
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')

# Función de logging
log() {
    local level="$1"
    shift
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] [$SCRIPT_NAME] $*" | tee -a "$LOG_FILE"
    
    if [ "$level" = "ERROR" ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] [$SCRIPT_NAME] $*" >> "$ERROR_LOG"
    fi
}

# Función para manejar errores
error_exit() {
    log "ERROR" "$1"
    exit 1
}

# Función para verificar si es necesario hacer backup incremental
check_if_backup_needed() {
    log "INFO" "Verificando si hay cambios que respaldar..."
    
    # Verificar última modificación en directorios de datos
    local needs_backup=false
    local dirs_to_check=(
        "/data/nextcloud"
        "/data/nextcloud_data"
        "/data/redis"
    )
    
    # Archivo para trackear última sincronización
    local last_sync_file="/app/logs/last_incremental_sync"
    local last_sync_time=0
    
    if [ -f "$last_sync_file" ]; then
        last_sync_time=$(cat "$last_sync_file")
    fi
    
    # Verificar si hay archivos modificados desde la última sincronización
    for dir in "${dirs_to_check[@]}"; do
        if [ -d "$dir" ]; then
            local latest_modification
            latest_modification=$(find "$dir" -type f -printf '%T@\n' 2>/dev/null | sort -n | tail -1 || echo "0")
            
            if (( $(echo "$latest_modification > $last_sync_time" | bc -l 2>/dev/null || echo "1") )); then
                needs_backup=true
                log "INFO" "Detectados cambios en: $dir"
            fi
        fi
    done
    
    if [ "$needs_backup" = "true" ]; then
        log "INFO" "Se requiere backup incremental"
        return 0
    else
        log "INFO" "No hay cambios detectados, omitiendo backup incremental"
        return 1
    fi
}

# Función para backup incremental de archivos
backup_files_incremental() {
    log "INFO" "Iniciando backup incremental de archivos..."
    
    # Verificar conectividad SSH
    if ! ssh -o ConnectTimeout=30 -o BatchMode=yes \
        "$BACKUP_REMOTE_USER@$BACKUP_REMOTE_HOST" "echo 'SSH OK'" >/dev/null 2>&1; then
        error_exit "No se puede conectar al servidor remoto via SSH"
    fi
    
    # Directorios a sincronizar
    local backup_sources=(
        "/data/nextcloud:nextcloud"
        "/data/nextcloud_data:nextcloud_data" 
        "/data/redis:redis"
    )
    
    # Configuración de rsync para backup incremental
    local rsync_opts=(
        "--archive"                    # Preservar permisos, timestamps, etc.
        "--verbose"                    # Salida detallada
        "--compress"                   # Compresión durante transferencia
        "--delete"                     # Eliminar archivos que ya no existen
        "--backup"                     # Crear backup de archivos modificados
        "--backup-dir=../incremental_$TIMESTAMP"  # Directorio para backups incrementales
        "--update"                     # Solo transferir si el archivo es más nuevo
        "--progress"                   # Mostrar progreso
        "--stats"                      # Mostrar estadísticas
        "--human-readable"             # Tamaños legibles por humanos
        "--itemize-changes"            # Mostrar qué cambió
        "--exclude=*.tmp"              # Excluir archivos temporales
        "--exclude=*.lock"             # Excluir archivos de bloqueo
        "--exclude=.DS_Store"          # Excluir archivos de macOS
        "--exclude=Thumbs.db"          # Excluir archivos de Windows
    )
    
    # SSH options para conexión segura
    local ssh_opts="-o ConnectTimeout=30 -o ServerAliveInterval=60 -o ServerAliveCountMax=3"
    
    # Sincronizar cada directorio
    for source_mapping in "${backup_sources[@]}"; do
        local source_dir="${source_mapping%%:*}"
        local dest_name="${source_mapping##*:}"
        
        if [ -d "$source_dir" ]; then
            log "INFO" "Sincronizando incremental: $source_dir -> $dest_name"
            
            # Ejecutar rsync incremental al servidor remoto
            if ! rsync "${rsync_opts[@]}" \
                -e "ssh $ssh_opts" \
                "$source_dir/" \
                "$BACKUP_REMOTE_USER@$BACKUP_REMOTE_HOST:$BACKUP_REMOTE_PATH/current/$dest_name/"; then
                error_exit "Error en rsync incremental para: $source_dir"
            fi
            
            log "INFO" "Sincronización incremental completada: $dest_name"
        else
            log "WARN" "Directorio fuente no encontrado: $source_dir"
        fi
    done
    
    # Actualizar timestamp de última sincronización
    date +%s.%N > "/app/logs/last_incremental_sync"
    
    log "INFO" "Backup incremental de archivos completado"
}

# Función para crear snapshot de metadatos incrementales
create_incremental_metadata() {
    log "INFO" "Creando metadatos del backup incremental..."
    
    local metadata_content=$(cat << EOF
{
    "backup_type": "incremental",
    "timestamp": "$TIMESTAMP",
    "date": "$(date -Iseconds)",
    "hostname": "$(hostname)",
    "script_version": "1.0.0",
    "parent_backup": "$(find /backups/local/files -maxdepth 1 -type d -name "20*" | sort | tail -1 | xargs basename 2>/dev/null || echo 'none')",
    "remote": {
        "host": "$BACKUP_REMOTE_HOST",
        "user": "$BACKUP_REMOTE_USER",
        "path": "$BACKUP_REMOTE_PATH"
    }
}
EOF
)
    
    # Guardar metadatos localmente
    echo "$metadata_content" > "/app/logs/incremental_metadata_$TIMESTAMP.json"
    
    # Enviar metadatos al servidor remoto
    echo "$metadata_content" | ssh "$BACKUP_REMOTE_USER@$BACKUP_REMOTE_HOST" \
        "cat > '$BACKUP_REMOTE_PATH/incremental_metadata_$TIMESTAMP.json'"
    
    log "INFO" "Metadatos incrementales creados"
}

# Función para verificar estado del backup remoto
verify_remote_backup() {
    log "INFO" "Verificando estado del backup remoto..."
    
    # Obtener estadísticas del directorio remoto
    local remote_stats
    remote_stats=$(ssh "$BACKUP_REMOTE_USER@$BACKUP_REMOTE_HOST" \
        "find '$BACKUP_REMOTE_PATH/current' -type f | wc -l 2>/dev/null || echo '0'")
    
    log "INFO" "Archivos en backup remoto: $remote_stats"
    
    # Verificar espacio disponible en servidor remoto
    local remote_space
    remote_space=$(ssh "$BACKUP_REMOTE_USER@$BACKUP_REMOTE_HOST" \
        "df -h '$BACKUP_REMOTE_PATH' | tail -1" 2>/dev/null || echo "No disponible")
    
    log "INFO" "Espacio en servidor remoto: $remote_space"
}

# Función principal
main() {
    local start_time=$(date +%s)
    
    log "INFO" "=== INICIANDO BACKUP INCREMENTAL ==="
    log "INFO" "Timestamp: $TIMESTAMP"
    
    # Verificar variables de entorno requeridas
    if [ -z "${BACKUP_REMOTE_HOST:-}" ] || [ -z "${BACKUP_REMOTE_USER:-}" ] || [ -z "${BACKUP_REMOTE_PATH:-}" ]; then
        error_exit "Variables de configuración remota no definidas"
    fi
    
    # Verificar si es necesario hacer backup
    if ! check_if_backup_needed; then
        log "INFO" "No se requiere backup incremental en este momento"
        exit 0
    fi
    
    # Ejecutar backup incremental
    backup_files_incremental
    
    # Crear metadatos
    create_incremental_metadata
    
    # Verificar estado del backup
    verify_remote_backup
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    log "INFO" "=== BACKUP INCREMENTAL FINALIZADO ==="
    log "INFO" "Duración total: $duration segundos"
    log "INFO" "✓ Backup incremental exitoso"
}

# Ejecutar función principal
main "$@"