#!/bin/bash
# ===================================================================================
# NEXTCLOUD BACKUP - CONFIGURACIÓN AUTOMÁTICA COMPLETA
# ===================================================================================
# 
# Este script:
# 1. Genera llaves SSH en el host (reutilizables para todos los contenedores)
# 2. Configura el entorno automáticamente
# 3. Prepara la infraestructura para backup automatizado
# 4. Reinicia todos los servicios con IPs estáticas
# ===================================================================================

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Configuración
PROJECT_DIR="/home/uceda/Documents/PROYECTO_V1"
SSH_KEYS_DIR="$PROJECT_DIR/ssh-keys"
BACKUP_SSH_DIR="$PROJECT_DIR/nextcloud-backup/ssh-keys"

# Función para imprimir mensajes con colores
print_message() {
    local color=$1
    shift
    echo -e "${color}$@${NC}"
}

print_header() {
    echo
    print_message $BLUE "═══════════════════════════════════════════════════════════"
    print_message $BLUE "  $1"
    print_message $BLUE "═══════════════════════════════════════════════════════════"
}

print_success() {
    print_message $GREEN "✓ $1"
}

print_warning() {
    print_message $YELLOW "⚠ $1"
}

print_error() {
    print_message $RED "✗ $1"
}

print_info() {
    print_message $PURPLE "ℹ $1"
}

# Función para verificar que estamos en el directorio correcto
check_project_directory() {
    if [ ! -f "docker-compose.yml" ]; then
        print_error "No se encontró docker-compose.yml en el directorio actual"
        print_info "Asegúrate de estar en: $PROJECT_DIR"
        exit 1
    fi
    
    if [ ! -f ".env" ]; then
        print_error "No se encontró archivo .env"
        exit 1
    fi
    
    print_success "Directorio del proyecto verificado"
}

# Función para generar llaves SSH maestras en el host
generate_master_ssh_keys() {
    print_header "GENERANDO LLAVES SSH MAESTRAS"
    
    # Crear directorio para llaves SSH globales
    mkdir -p "$SSH_KEYS_DIR"
    
    local ssh_key="$SSH_KEYS_DIR/nextcloud_backup_key"
    
    if [ -f "$ssh_key" ]; then
        print_warning "Las llaves SSH maestras ya existen"
        read -p "¿Deseas regenerarlas? (s/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Ss]$ ]]; then
            print_info "Usando llaves existentes"
            return
        fi
        rm -f "$ssh_key" "$ssh_key.pub"
    fi
    
    print_info "Generando nuevas llaves SSH RSA 4096 bits..."
    
    # Generar llaves SSH maestras
    ssh-keygen -t rsa -b 4096 \
               -f "$ssh_key" \
               -N "" \
               -C "nextcloud-backup-master@$(hostname)-$(date +%Y%m%d)"
    
    # Establecer permisos correctos
    chmod 600 "$ssh_key"
    chmod 644 "$ssh_key.pub"
    
    print_success "Llaves SSH maestras generadas:"
    print_info "Privada: $ssh_key"
    print_info "Pública: $ssh_key.pub"
    
    # Mostrar la llave pública para configurar en servidor remoto
    print_header "LLAVE PÚBLICA PARA SERVIDOR REMOTO"
    print_warning "Copia esta llave al archivo ~/.ssh/authorized_keys de tu servidor de backup:"
    echo
    cat "$ssh_key.pub"
    echo
}

# Función para copiar llaves a directorios de contenedores
copy_ssh_keys_to_containers() {
    print_header "COPIANDO LLAVES SSH A CONTENEDORES"
    
    local master_key="$SSH_KEYS_DIR/nextcloud_backup_key"
    
    if [ ! -f "$master_key" ]; then
        print_error "No se encontraron llaves SSH maestras"
        return 1
    fi
    
    # Copiar a directorio de backup
    mkdir -p "$BACKUP_SSH_DIR"
    cp "$master_key" "$BACKUP_SSH_DIR/id_rsa"
    cp "$master_key.pub" "$BACKUP_SSH_DIR/id_rsa.pub"
    chmod 600 "$BACKUP_SSH_DIR/id_rsa"
    chmod 644 "$BACKUP_SSH_DIR/id_rsa.pub"
    
    print_success "Llaves copiadas al contenedor de backup"
    
    # Futuro: copiar a otros contenedores que necesiten SSH
    # mkdir -p "./other-service/ssh-keys"
    # cp "$master_key" "./other-service/ssh-keys/id_rsa"
    
    print_success "Llaves SSH distribuidas a todos los contenedores"
}

# Función para verificar y actualizar configuración de red
update_network_configuration() {
    print_header "VERIFICANDO CONFIGURACIÓN DE RED"
    
    # Verificar que el docker-compose tiene las IPs configuradas
    if grep -q "172.18.0.10" docker-compose.yml; then
        print_success "IPs estáticas ya configuradas en docker-compose.yml"
    else
        print_warning "IPs estáticas no encontradas en docker-compose.yml"
        print_info "El docker-compose.yml ya debería tener las IPs configuradas"
    fi
    
    # Mostrar la asignación de IPs
    print_info "Asignación de IPs estáticas:"
    echo "  • db (MariaDB):         172.18.0.10"
    echo "  • redis:               172.18.0.11"
    echo "  • nextcloud:           172.18.0.20"
    echo "  • coredns:             172.18.0.30"
    echo "  • nginx-proxy:         172.18.0.31"
    echo "  • portainer:           172.18.0.40"
    echo "  • xfce-desktop-a:      172.18.0.41"
    echo "  • xfce-desktop-b:      172.18.0.42"
    echo "  • xfce-desktop-c:      172.18.0.43"
    echo "  • nextcloud-backup:    172.18.0.50"
}

# Función para crear directorio de backup local
setup_backup_directories() {
    print_header "CONFIGURANDO DIRECTORIOS DE BACKUP"
    
    # Crear directorio temporal para backups locales
    local backup_temp_dir="/tmp/nextcloud-backups"
    mkdir -p "$backup_temp_dir"
    chmod 755 "$backup_temp_dir"
    
    # Crear directorios de logs si no existen
    mkdir -p "./nextcloud-backup/logs"
    
    print_success "Directorios de backup configurados"
    print_info "Backup temporal local: $backup_temp_dir"
}

# Función para verificar variables de entorno
verify_environment_variables() {
    print_header "VERIFICANDO VARIABLES DE ENTORNO"
    
    # Cargar .env
    source .env
    
    # Verificar variables críticas
    local required_vars=(
        "MYSQL_DATABASE"
        "MYSQL_USER" 
        "MYSQL_PASSWORD"
        "MYSQL_ROOT_PASSWORD"
        "NEXTCLOUD_ADMIN_USER"
        "NEXTCLOUD_ADMIN_PASSWORD"
    )
    
    local missing_vars=()
    
    for var in "${required_vars[@]}"; do
        if [ -z "${!var:-}" ]; then
            missing_vars+=("$var")
        else
            print_success "$var configurada"
        fi
    done
    
    if [ ${#missing_vars[@]} -gt 0 ]; then
        print_error "Variables faltantes en .env:"
        printf '  • %s\n' "${missing_vars[@]}"
        exit 1
    fi
    
    print_success "Todas las variables críticas están configuradas"
    
    # Mostrar configuración de backup
    print_info "Configuración de backup:"
    echo "  • Servidor remoto: ${BACKUP_REMOTE_HOST:-'localhost'}"
    echo "  • Usuario remoto:  ${BACKUP_REMOTE_USER:-'backup'}"
    echo "  • Ruta remota:     ${BACKUP_REMOTE_PATH:-'/tmp/nextcloud-backups'}"
    echo "  • Retención:       ${BACKUP_RETENTION_DAYS:-30} días"
}

# Función para detener servicios existentes
stop_existing_services() {
    print_header "DETENIENDO SERVICIOS EXISTENTES"
    
    # Detener todos los servicios
    if docker compose ps -q > /dev/null 2>&1; then
        print_info "Deteniendo servicios actuales..."
        docker compose down
        print_success "Servicios detenidos"
    else
        print_info "No hay servicios ejecutándose"
    fi
    
    # Limpiar volúmenes de red si es necesario
    print_info "Limpiando redes Docker anteriores..."
    docker network prune -f > /dev/null 2>&1 || true
    print_success "Redes limpiadas"
}

# Función para construir imágenes
build_images() {
    print_header "CONSTRUYENDO IMÁGENES DOCKER"
    
    print_info "Construyendo imagen de backup..."
    if docker compose build nextcloud-backup; then
        print_success "Imagen de backup construida exitosamente"
    else
        print_error "Error al construir imagen de backup"
        exit 1
    fi
    
    # Construir otras imágenes que puedan necesitarse
    print_info "Construyendo otras imágenes si es necesario..."
    docker compose build > /dev/null 2>&1 || true
    print_success "Todas las imágenes construidas"
}

# Función para iniciar servicios con nueva configuración
start_services() {
    print_header "INICIANDO SERVICIOS CON NUEVA CONFIGURACIÓN"
    
    print_info "Iniciando servicios de infraestructura primero..."
    
    # Iniciar en orden de dependencias
    docker compose up -d coredns
    sleep 5
    
    docker compose up -d db redis
    print_info "Esperando que la base de datos esté lista..."
    sleep 15
    
    docker compose up -d nextcloud nginx-proxy
    sleep 10
    
    print_info "Iniciando servicio de backup..."
    docker compose up -d nextcloud-backup
    sleep 5
    
    print_info "Iniciando servicios adicionales..."
    docker compose up -d portainer
    
    print_success "Todos los servicios iniciados"
}

# Función para verificar estado de los servicios
verify_services_status() {
    print_header "VERIFICANDO ESTADO DE LOS SERVICIOS"
    
    # Esperar un poco para que los servicios se estabilicen
    sleep 10
    
    # Verificar cada servicio crítico
    local services=("db" "redis" "nextcloud" "coredns" "nginx-proxy" "nextcloud-backup")
    
    for service in "${services[@]}"; do
        if docker compose ps "$service" | grep -q "Up"; then
            print_success "$service está ejecutándose"
        else
            print_error "$service no está ejecutándose correctamente"
            docker compose logs "$service" | tail -5
        fi
    done
    
    # Verificar conectividad de red
    print_info "Verificando conectividad de red..."
    
    # Test de conectividad del backup a la DB
    if docker compose exec -T nextcloud-backup nc -z db 3306 2>/dev/null; then
        print_success "Conectividad backup -> db: OK"
    else
        print_warning "Conectividad backup -> db: FALLO"
    fi
    
    # Test de conectividad del backup a redis
    if docker compose exec -T nextcloud-backup nc -z redis 6379 2>/dev/null; then
        print_success "Conectividad backup -> redis: OK"
    else
        print_warning "Conectividad backup -> redis: FALLO"
    fi
}

# Función para ejecutar test de backup
test_backup_functionality() {
    print_header "PROBANDO FUNCIONALIDAD DE BACKUP"
    
    print_info "Ejecutando health check..."
    if docker compose exec -T nextcloud-backup /app/scripts/health-check.sh; then
        print_success "Health check del backup: OK"
    else
        print_warning "Health check del backup: FALLÓ"
        print_info "Revisa los logs para más detalles"
    fi
    
    # Opcional: ejecutar un backup de prueba (solo si el usuario confirma)
    read -p "¿Deseas ejecutar un backup de prueba? (s/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        print_info "Ejecutando backup de prueba..."
        if docker compose exec -T nextcloud-backup /app/scripts/backup-full.sh; then
            print_success "Backup de prueba ejecutado exitosamente"
        else
            print_warning "Backup de prueba falló - revisa configuración del servidor remoto"
        fi
    fi
}

# Función para mostrar resumen final
show_final_summary() {
    print_header "CONFIGURACIÓN COMPLETADA"
    
    print_success "¡Infraestructura Nextcloud con backup automatizado configurada!"
    
    print_info "Servicios disponibles:"
    echo "  • Nextcloud:       https://nextcloud.net (o https://localhost)"
    echo "  • Portainer:       http://localhost:9000"
    echo "  • Desktop A:       http://localhost:6901 (VNC)"
    echo "  • Desktop B:       http://localhost:6902 (VNC)"
    echo "  • Desktop C:       http://localhost:6903 (VNC)"
    
    print_info "Configuración de backup:"
    echo "  • Backups completos: Diario a las 2:00 AM"
    echo "  • Backups incrementales: Cada 6 horas"
    echo "  • Logs disponibles: docker compose logs -f nextcloud-backup"
    
    print_info "Comandos útiles:"
    echo "  • Ver estado:      docker compose ps"
    echo "  • Ver logs:        docker compose logs -f [servicio]"
    echo "  • Backup manual:   docker compose exec nextcloud-backup /app/scripts/backup-full.sh"
    echo "  • Health check:    docker compose exec nextcloud-backup /app/scripts/health-check.sh"
    
    print_warning "IMPORTANTE:"
    echo "  • Configura tu servidor remoto de backup con la llave pública mostrada"
    echo "  • Actualiza BACKUP_REMOTE_HOST en .env con tu servidor real"
    echo "  • Las llaves SSH maestras están en: $SSH_KEYS_DIR"
    
    print_success "¡Configuración automática completada exitosamente!"
}

# Función principal
main() {
    print_header "NEXTCLOUD BACKUP - CONFIGURACIÓN AUTOMÁTICA COMPLETA"
    print_info "Este script configurará automáticamente todo el sistema de backup"
    echo
    
    # Cambiar al directorio del proyecto
    cd "$PROJECT_DIR" || exit 1
    
    # Ejecutar todas las funciones en orden
    check_project_directory
    generate_master_ssh_keys
    copy_ssh_keys_to_containers
    update_network_configuration
    setup_backup_directories
    verify_environment_variables
    stop_existing_services
    build_images
    start_services
    verify_services_status
    test_backup_functionality
    show_final_summary
    
    print_success "¡Proceso completo finalizado!"
}

# Verificar que se está ejecutando como script principal
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    main "$@"
fi