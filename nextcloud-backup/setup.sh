#!/bin/bash
# ===================================================================================
# NEXTCLOUD BACKUP SERVICE - CONFIGURACIÓN INICIAL
# ===================================================================================

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para imprimir mensajes con colores
print_message() {
    local color=$1
    shift
    echo -e "${color}$@${NC}"
}

print_header() {
    echo
    print_message $BLUE "=== $1 ==="
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

# Función para verificar dependencias
check_dependencies() {
    print_header "Verificando dependencias"
    
    local dependencies=("ssh-keygen" "docker")
    
    for dep in "${dependencies[@]}"; do
        if command -v $dep >/dev/null 2>&1; then
            print_success "$dep está instalado"
        else
            print_error "$dep no está instalado"
            exit 1
        fi
    done
    
    # Verificar Docker Compose (v2 sintaxis)
    if docker compose version >/dev/null 2>&1; then
        print_success "docker compose está disponible"
    else
        print_error "docker compose no está disponible"
        exit 1
    fi
}

# Función para generar llaves SSH
generate_ssh_keys() {
    print_header "Configurando llaves SSH"
    
    local ssh_key_path="./nextcloud-backup/ssh-keys/id_rsa"
    
    if [ -f "$ssh_key_path" ]; then
        print_warning "Las llaves SSH ya existen"
        read -p "¿Deseas regenerarlas? (s/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Ss]$ ]]; then
            print_message $BLUE "Manteniendo llaves existentes"
            return
        fi
    fi
    
    print_message $BLUE "Generando nuevas llaves SSH..."
    
    # Crear directorio si no existe
    mkdir -p "$(dirname "$ssh_key_path")"
    
    # Generar llaves SSH
    ssh-keygen -t rsa -b 4096 -f "$ssh_key_path" -N "" -C "nextcloud-backup@$(hostname)"
    
    # Establecer permisos correctos
    chmod 600 "$ssh_key_path"
    chmod 644 "$ssh_key_path.pub"
    
    print_success "Llaves SSH generadas en: $ssh_key_path"
    
    # Mostrar llave pública
    print_header "Llave pública generada"
    print_message $YELLOW "Copia esta llave al archivo ~/.ssh/authorized_keys de tu servidor de backup:"
    echo
    cat "$ssh_key_path.pub"
    echo
}

# Función para configurar variables de entorno
setup_environment() {
    print_header "Configurando variables de entorno"
    
    local env_file=".env"
    
    if [ ! -f "$env_file" ]; then
        print_error "Archivo .env no encontrado. Créalo primero."
        exit 1
    fi
    
    # Verificar si ya existen variables de backup
    if grep -q "BACKUP_REMOTE_HOST" "$env_file"; then
        print_warning "Variables de backup ya configuradas en .env"
        read -p "¿Deseas reconfigurarlas? (s/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Ss]$ ]]; then
            return
        fi
    fi
    
    # Solicitar configuración interactiva
    print_message $BLUE "Configuración del servidor de backup remoto:"
    echo
    
    read -p "Servidor remoto (IP o hostname): " backup_host
    read -p "Usuario SSH: " backup_user
    read -p "Puerto SSH [22]: " backup_port
    backup_port=${backup_port:-22}
    read -p "Ruta remota para backups: " backup_path
    
    print_message $BLUE "Configuración adicional:"
    read -p "Días de retención [30]: " retention_days
    retention_days=${retention_days:-30}
    
    # Agregar variables al .env
    echo "" >> "$env_file"
    echo "# ==============================" >> "$env_file"
    echo "# CONFIGURACIÓN DE BACKUP" >> "$env_file"
    echo "# ==============================" >> "$env_file"
    echo "BACKUP_REMOTE_HOST=$backup_host" >> "$env_file"
    echo "BACKUP_REMOTE_USER=$backup_user" >> "$env_file"
    echo "BACKUP_REMOTE_PORT=$backup_port" >> "$env_file"
    echo "BACKUP_REMOTE_PATH=$backup_path" >> "$env_file"
    echo "BACKUP_RETENTION_DAYS=$retention_days" >> "$env_file"
    echo "BACKUP_COMPRESSION=true" >> "$env_file"
    echo "BACKUP_VERIFY_CHECKSUMS=true" >> "$env_file"
    echo "BACKUP_RUN_INITIAL=false" >> "$env_file"
    echo "LOG_RETENTION_DAYS=7" >> "$env_file"
    
    print_success "Variables agregadas a $env_file"
}

# Función para probar conectividad
test_connectivity() {
    print_header "Probando conectividad"
    
    # Cargar variables del .env
    if [ -f ".env" ]; then
        source .env
    else
        print_error "Archivo .env no encontrado"
        return 1
    fi
    
    if [ -z "$BACKUP_REMOTE_HOST" ] || [ -z "$BACKUP_REMOTE_USER" ]; then
        print_warning "Variables de backup no configuradas"
        return 1
    fi
    
    local ssh_key="./nextcloud-backup/ssh-keys/id_rsa"
    
    if [ ! -f "$ssh_key" ]; then
        print_error "Llave SSH no encontrada: $ssh_key"
        return 1
    fi
    
    print_message $BLUE "Probando conexión SSH a $BACKUP_REMOTE_USER@$BACKUP_REMOTE_HOST..."
    
    if ssh -i "$ssh_key" -o ConnectTimeout=10 -o StrictHostKeyChecking=no \
       "$BACKUP_REMOTE_USER@$BACKUP_REMOTE_HOST" "echo 'Conexión exitosa'" 2>/dev/null; then
        print_success "Conectividad SSH OK"
        
        # Probar creación de directorio remoto
        print_message $BLUE "Verificando directorio remoto..."
        if ssh -i "$ssh_key" "$BACKUP_REMOTE_USER@$BACKUP_REMOTE_HOST" \
           "mkdir -p '$BACKUP_REMOTE_PATH' && echo 'Directorio OK'" 2>/dev/null; then
            print_success "Directorio remoto accesible: $BACKUP_REMOTE_PATH"
        else
            print_error "No se puede crear/acceder al directorio remoto"
        fi
    else
        print_error "No se puede conectar al servidor remoto"
        print_message $BLUE "Verifica que:"
        echo "  1. El servidor está accesible"
        echo "  2. La llave pública está en ~/.ssh/authorized_keys del servidor"
        echo "  3. El usuario tiene permisos correctos"
    fi
}

# Función para construir el contenedor
build_container() {
    print_header "Construyendo contenedor de backup"
    
    if docker compose build nextcloud-backup; then
        print_success "Contenedor construido exitosamente"
    else
        print_error "Error al construir el contenedor"
        exit 1
    fi
}

# Función para mostrar resumen de configuración
show_summary() {
    print_header "Resumen de configuración"
    
    local ssh_key_pub="./nextcloud-backup/ssh-keys/id_rsa.pub"
    
    if [ -f "$ssh_key_pub" ]; then
        print_message $GREEN "✓ Llaves SSH configuradas"
    else
        print_message $RED "✗ Llaves SSH no encontradas"
    fi
    
    if [ -f ".env" ] && grep -q "BACKUP_REMOTE_HOST" ".env"; then
        print_message $GREEN "✓ Variables de entorno configuradas"
    else
        print_message $RED "✗ Variables de entorno no configuradas"
    fi
    
    print_header "Próximos pasos"
    echo "1. Ejecuta: docker compose up -d nextcloud-backup"
    echo "2. Verifica logs: docker compose logs -f nextcloud-backup"
    echo "3. Ejecuta backup manual: docker compose exec nextcloud-backup /app/scripts/backup-full.sh"
    echo
}

# Función principal
main() {
    print_header "NEXTCLOUD BACKUP SERVICE - CONFIGURACIÓN INICIAL"
    
    check_dependencies
    generate_ssh_keys
    setup_environment
    test_connectivity
    build_container
    show_summary
    
    print_success "Configuración completada"
}

# Ejecutar si se llama directamente
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    main "$@"
fi