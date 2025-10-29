#!/bin/bash

# Script para desinstalar certificado SSL autofirmado del sistema Linux

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

CERT_NAME="nextcloud-local-ca"

echo -e "${BLUE}=================================================${NC}"
echo -e "${BLUE}  Desinstalador de Certificado SSL Local${NC}"
echo -e "${BLUE}  Para nextcloud.net${NC}"
echo -e "${BLUE}=================================================${NC}"
echo ""

# Función para mostrar mensajes
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Detectar la distribución Linux
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$NAME
else
    log_error "No se pudo detectar la distribución Linux"
    exit 1
fi

log_info "Sistema detectado: $OS"

# Verificar permisos de sudo
if ! sudo -n true 2>/dev/null; then
    log_warning "Este script requiere permisos de administrador (sudo)"
    log_info "Se te pedirá la contraseña de sudo..."
fi

# Confirmar desinstalación
echo ""
log_warning "¿Estás seguro de que deseas desinstalar el certificado SSL de nextcloud.net?"
log_info "Esto hará que los navegadores vuelvan a mostrar advertencias de seguridad"
echo ""
read -p "¿Continuar con la desinstalación? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_info "Desinstalación cancelada por el usuario"
    exit 0
fi

# Función para desinstalar en Ubuntu/Debian
uninstall_ubuntu_debian() {
    log_info "Desinstalando certificado de Ubuntu/Debian..."
    
    CERT_PATH="/usr/local/share/ca-certificates/${CERT_NAME}.crt"
    
    if [ -f "$CERT_PATH" ]; then
        sudo rm "$CERT_PATH"
        sudo update-ca-certificates --fresh
        log_success "Certificado desinstalado exitosamente"
    else
        log_warning "Certificado no encontrado en $CERT_PATH"
    fi
}

# Función para desinstalar en CentOS/RHEL/Fedora
uninstall_redhat() {
    log_info "Desinstalando certificado de CentOS/RHEL/Fedora..."
    
    CERT_PATH="/etc/pki/ca-trust/source/anchors/${CERT_NAME}.crt"
    
    if [ -f "$CERT_PATH" ]; then
        sudo rm "$CERT_PATH"
        sudo update-ca-trust
        log_success "Certificado desinstalado exitosamente"
    else
        log_warning "Certificado no encontrado en $CERT_PATH"
    fi
}

# Función para desinstalar en Arch Linux
uninstall_arch() {
    log_info "Desinstalando certificado de Arch Linux..."
    
    CERT_PATH="/etc/ca-certificates/trust-source/anchors/${CERT_NAME}.crt"
    
    if [ -f "$CERT_PATH" ]; then
        sudo rm "$CERT_PATH"
        sudo trust extract-compat
        log_success "Certificado desinstalado exitosamente"
    else
        log_warning "Certificado no encontrado en $CERT_PATH"
    fi
}

# Desinstalar según la distribución
case "$OS" in
    *"Ubuntu"*|*"Debian"*|*"Linux Mint"*|*"Pop!_OS"*)
        uninstall_ubuntu_debian
        ;;
    *"CentOS"*|*"Red Hat"*|*"Fedora"*|*"Rocky"*|*"AlmaLinux"*)
        uninstall_redhat
        ;;
    *"Arch"*|*"Manjaro"*|*"EndeavourOS"*)
        uninstall_arch
        ;;
    *)
        log_warning "Distribución no reconocida: $OS"
        log_info "Intentando método genérico para Ubuntu/Debian..."
        uninstall_ubuntu_debian
        ;;
esac

echo ""
echo -e "${GREEN}=================================================${NC}"
echo -e "${GREEN}  🗑️  DESINSTALACIÓN COMPLETADA${NC}"
echo -e "${GREEN}=================================================${NC}"
echo ""
echo -e "${YELLOW}Pasos siguientes:${NC}"
echo "  1. Reinicia tus navegadores"
echo "  2. Los sitios https://nextcloud.net volverán a mostrar advertencias de certificado"
echo "  3. Usa 'curl -k' para conexiones de desarrollo que ignoren certificados"
echo ""
echo -e "${BLUE}Para reinstalar el certificado ejecuta:${NC}"
echo "  ${YELLOW}./install-ssl-cert-system.sh${NC}"
echo ""