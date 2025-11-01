#!/bin/bash
# ===================================================================================
# NEXTCLOUD BACKUP - BACKUP COMPLETO
# ===================================================================================
# 
# FUNCIONALIDAD:
# - Backup completo de base de datos MySQL/MariaDB
# - Sincronización completa de archivos via RSYNC
# - Transferencia encriptada al servidor remoto
# - Verificación de integridad y logs detallados
# ===================================================================================

set -euo pipefail

# Configuración de logging
SCRIPT_NAME="backup-full"
LOG_FILE="/app/logs/backup.log"
ERROR_LOG="/app/logs/error.log"
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')

# Función de logging mejorada
log() {
    local level="$1"
    shift
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] [$SCRIPT_NAME] $*" | tee -a "$LOG_FILE"
    
    # También enviar errores al log de errores
    if [ "$level" = "ERROR" ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] [$SCRIPT_NAME] $*" >> "$ERROR_LOG"
    fi
}

# Función para manejar errores
error_exit() {
    log "ERROR" "$1"
    exit 1
}

# Función para verificar variables requeridas
check_env() {
    log "INFO" "Verificando configuración..."
    
    # Variables críticas requeridas
    local required_vars=(
        "BACKUP_DB_HOST"
        "BACKUP_DB_USER" 
        "BACKUP_DB_PASSWORD"
        "BACKUP_DB_NAME"
    )
    
    # Variables de servidor remoto (con valores por defecto para desarrollo)
    local remote_vars=(
        "BACKUP_REMOTE_HOST"
        "BACKUP_REMOTE_USER"
        "BACKUP_REMOTE_PATH"
    )
    
    # Verificar variables críticas
    local missing_vars=()
    for var in "${required_vars[@]}"; do
        if [ -z "${!var:-}" ]; then
            missing_vars+=("$var")
        else
            log "INFO" "✓ $var configurada"
        fi
    done
    
    if [ ${#missing_vars[@]} -gt 0 ]; then
        error_exit "Variables críticas faltantes: ${missing_vars[*]}"
    fi
    
    # Verificar variables de servidor remoto
    local remote_missing=()
    for var in "${remote_vars[@]}"; do
        if [ -z "${!var:-}" ]; then
            remote_missing+=("$var")
        else
            log "INFO" "✓ $var configurada: ${!var}"
        fi
    done
    
    if [ ${#remote_missing[@]} -gt 0 ]; then
        log "WARN" "Variables de servidor remoto faltantes: ${remote_missing[*]}"
        log "WARN" "El backup se ejecutará solo localmente"
        export BACKUP_LOCAL_ONLY=true
    else
        export BACKUP_LOCAL_ONLY=false
        log "INFO" "Configuración remota completa - backup completo habilitado"
    fi
    
    # Mostrar configuración actual
    log "INFO" "Configuración de backup:"
    log "INFO" "  Base de datos: ${BACKUP_DB_HOST}:${BACKUP_DB_PORT:-3306}/${BACKUP_DB_NAME}"
    log "INFO" "  Usuario DB: ${BACKUP_DB_USER}"
    log "INFO" "  Proyecto: ${PROJECT_NAME:-'N/A'}"
    if [ "$BACKUP_LOCAL_ONLY" != "true" ]; then
        log "INFO" "  Servidor remoto: ${BACKUP_REMOTE_USER}@${BACKUP_REMOTE_HOST}:${BACKUP_REMOTE_PATH}"
    fi
    log "INFO" "  Retención: ${BACKUP_RETENTION_DAYS:-30} días"
    log "INFO" "  Compresión: ${BACKUP_COMPRESSION:-true}"
}

# Función para crear backup de base de datos
backup_database() {
    log "INFO" "Iniciando backup de base de datos..."
    
    local db_backup_dir="/backups/local/db"
    local db_backup_file="$db_backup_dir/nextcloud_db_$TIMESTAMP.sql"
    
    # Crear directorio si no existe
    mkdir -p "$db_backup_dir"
    
    # Crear backup de la base de datos
    log "INFO" "Creando dump de base de datos: $BACKUP_DB_NAME"
    
    if ! mariadb-dump \
        --host="$BACKUP_DB_HOST" \
        --port="${BACKUP_DB_PORT:-3306}" \
        --user="$BACKUP_DB_USER" \
        --password="$BACKUP_DB_PASSWORD" \
        --single-transaction \
        --routines \
        --triggers \
        --events \
        --opt \
        --verbose \
        --ssl-ca="/etc/mysql/ssl/ca.pem" \
        --ssl-cert="/etc/mysql/ssl/client-cert.pem" \
        --ssl-key="/etc/mysql/ssl/client-key.pem" \
        "$BACKUP_DB_NAME" > "$db_backup_file"; then
        error_exit "Error al crear backup de base de datos"
    fi
    
    # Comprimir backup si está habilitado
    if [ "${BACKUP_COMPRESSION:-true}" = "true" ]; then
        log "INFO" "Comprimiendo backup de base de datos..."
        gzip "$db_backup_file"
        db_backup_file="$db_backup_file.gz"
    fi
    
    # Verificar integridad del backup
    if [ "${BACKUP_VERIFY_CHECKSUMS:-true}" = "true" ]; then
        log "INFO" "Generando checksum para verificación..."
        md5sum "$db_backup_file" > "$db_backup_file.md5"
    fi
    
    log "INFO" "Backup de base de datos completado: $(basename "$db_backup_file")"
    echo "$db_backup_file"
}

# Función para backup de archivos con rsync
backup_files() {
    log "INFO" "Iniciando backup de archivos..."
    
    local files_backup_dir="/backups/local/files"
    local timestamp_dir="$files_backup_dir/$TIMESTAMP"
    
    # Crear directorio de backup
    mkdir -p "$timestamp_dir"
    
    # Definir directorios a respaldar
    local backup_sources=(
        "/data/nextcloud:/nextcloud"
        "/data/nextcloud_data:/nextcloud_data"
        "/data/redis:/redis"
    )
    
    # Rsync de cada directorio fuente
    for source_mapping in "${backup_sources[@]}"; do
        local source_dir="${source_mapping%%:*}"
        local dest_name="${source_mapping##*:}"
        local dest_dir="$timestamp_dir/$dest_name"
        
        if [ -d "$source_dir" ]; then
            log "INFO" "Respaldando: $source_dir -> $dest_name"
            
            # Crear directorio destino
            mkdir -p "$dest_dir"
            
            # Ejecutar rsync local
            if ! rsync -av \
                --delete \
                --compress \
                --progress \
                --stats \
                --human-readable \
                "$source_dir/" "$dest_dir/"; then
                error_exit "Error en rsync local para: $source_dir"
            fi
            
            log "INFO" "Backup local completado: $dest_name"
        else
            log "WARN" "Directorio fuente no encontrado: $source_dir"
        fi
    done
    
    # Crear archivo de metadatos
    create_metadata "$timestamp_dir"
    
    log "INFO" "Backup local de archivos completado en: $timestamp_dir"
    echo "$timestamp_dir"
}

# Función para crear metadatos del backup
create_metadata() {
    local backup_dir="$1"
    local metadata_file="$backup_dir/backup_metadata.json"
    
    log "INFO" "Creando metadatos del backup..."
    
    cat > "$metadata_file" << EOF
{
    "backup_type": "full",
    "timestamp": "$TIMESTAMP",
    "date": "$(date -Iseconds)",
    "hostname": "$(hostname)",
    "script_version": "1.0.0",
    "configuration": {
        "compression": "${BACKUP_COMPRESSION:-true}",
        "verify_checksums": "${BACKUP_VERIFY_CHECKSUMS:-true}",
        "retention_days": "${BACKUP_RETENTION_DAYS:-30}"
    },
    "database": {
        "host": "$BACKUP_DB_HOST",
        "port": "${BACKUP_DB_PORT:-3306}",
        "database": "$BACKUP_DB_NAME",
        "user": "$BACKUP_DB_USER"
    },
    "remote": {
        "host": "$BACKUP_REMOTE_HOST",
        "user": "$BACKUP_REMOTE_USER",
        "path": "$BACKUP_REMOTE_PATH"
    }
}
EOF
    
    log "INFO" "Metadatos creados: $(basename "$metadata_file")"
}

# Función para sincronizar al servidor remoto
sync_to_remote() {
    local local_backup_dir="$1"
    local db_backup_file="$2"
    
    # Verificar si debe ejecutar sync remoto
    if [ "$BACKUP_LOCAL_ONLY" = "true" ]; then
        log "INFO" "Modo local habilitado - omitiendo sincronización remota"
        log "INFO" "Backup disponible localmente en:"
        log "INFO" "  DB: $db_backup_file"
        log "INFO" "  Archivos: $local_backup_dir"
        return 0
    fi
    
    log "INFO" "Iniciando sincronización al servidor remoto..."
    
    # Verificar conectividad SSH
    if ! ssh -o ConnectTimeout=30 -o BatchMode=yes \
        "$BACKUP_REMOTE_USER@$BACKUP_REMOTE_HOST" "echo 'SSH OK'" >/dev/null 2>&1; then
        log "ERROR" "No se puede conectar al servidor remoto via SSH"
        log "WARN" "Continuando con backup local solamente"
        export BACKUP_LOCAL_ONLY=true
        return 0
    fi
    
    # Crear directorio remoto si no existe
    log "INFO" "Creando directorio remoto: $BACKUP_REMOTE_PATH"
    ssh "$BACKUP_REMOTE_USER@$BACKUP_REMOTE_HOST" \
        "mkdir -p '$BACKUP_REMOTE_PATH/db' '$BACKUP_REMOTE_PATH/files'"
    
    # Sincronizar backup de base de datos
    log "INFO" "Sincronizando backup de base de datos..."
    if ! rsync -avz \
        --progress \
        --stats \
        --human-readable \
        -e "ssh -o ConnectTimeout=30" \
        "$db_backup_file"* \
        "$BACKUP_REMOTE_USER@$BACKUP_REMOTE_HOST:$BACKUP_REMOTE_PATH/db/"; then
        error_exit "Error al sincronizar backup de base de datos"
    fi
    
    # Sincronizar archivos
    log "INFO" "Sincronizando archivos..."
    if ! rsync -avz \
        --progress \
        --stats \
        --human-readable \
        --delete \
        -e "ssh -o ConnectTimeout=30" \
        "$local_backup_dir/" \
        "$BACKUP_REMOTE_USER@$BACKUP_REMOTE_HOST:$BACKUP_REMOTE_PATH/files/$TIMESTAMP/"; then
        error_exit "Error al sincronizar archivos"
    fi
    
    log "INFO" "Sincronización al servidor remoto completada"
}

# Función para limpiar backups antiguos
cleanup_old_backups() {
    log "INFO" "Limpiando backups antiguos..."
    
    local retention_days="${BACKUP_RETENTION_DAYS:-30}"
    
    # Limpiar backups locales antiguos
    find /backups/local/db -name "*.sql*" -mtime +$retention_days -delete 2>/dev/null || true
    find /backups/local/files -maxdepth 1 -type d -mtime +$retention_days -exec rm -rf {} \; 2>/dev/null || true
    
    # Limpiar backups remotos antiguos
    ssh "$BACKUP_REMOTE_USER@$BACKUP_REMOTE_HOST" \
        "find '$BACKUP_REMOTE_PATH/db' -name '*.sql*' -mtime +$retention_days -delete 2>/dev/null || true; \
         find '$BACKUP_REMOTE_PATH/files' -maxdepth 1 -type d -mtime +$retention_days -exec rm -rf {} \; 2>/dev/null || true"
    
    log "INFO" "Limpieza completada (reteniendo $retention_days días)"
}

# Función principal
main() {
    local start_time=$(date +%s)
    
    log "INFO" "=== INICIANDO BACKUP COMPLETO ==="
    log "INFO" "Timestamp: $TIMESTAMP"
    
    # Verificar configuración
    check_env
    
    # Ejecutar backups
    local db_backup_file
    local files_backup_dir
    
    db_backup_file=$(backup_database)
    files_backup_dir=$(backup_files)
    
    # Sincronizar al servidor remoto
    sync_to_remote "$files_backup_dir" "$db_backup_file"
    
    # Limpiar backups antiguos
    cleanup_old_backups
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    log "INFO" "=== BACKUP COMPLETO FINALIZADO ==="
    log "INFO" "Duración total: $duration segundos"
    log "INFO" "Backup de BD: $(basename "$db_backup_file")"
    log "INFO" "Backup de archivos: $(basename "$files_backup_dir")"
    
    # Verificación final
    log "INFO" "Verificando backup remoto..."
    ssh "$BACKUP_REMOTE_USER@$BACKUP_REMOTE_HOST" \
        "ls -la '$BACKUP_REMOTE_PATH/files/$TIMESTAMP/' && ls -la '$BACKUP_REMOTE_PATH/db/$(basename "$db_backup_file")'"
    
    log "INFO" "✓ Backup completo exitoso"
}

# Ejecutar función principal
main "$@"