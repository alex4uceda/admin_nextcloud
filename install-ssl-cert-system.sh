#!/bin/bash

# Script para instalar certificado SSL autofirmado en el sistema Linux
# Esto eliminará las advertencias de certificado en los navegadores

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuración
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CERT_FILE="$PROJECT_DIR/swag-config/etc/letsencrypt/live/nextcloud.net/fullchain.pem"
CERT_NAME="nextcloud-local-ca"

echo -e "${BLUE}=================================================${NC}"
echo -e "${BLUE}  Instalador de Certificado SSL Local${NC}"
echo -e "${BLUE}  Para nextcloud.net y subdominios${NC}"
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

# Verificar que el certificado existe
if [ ! -f "$CERT_FILE" ]; then
    log_error "Certificado no encontrado en: $CERT_FILE"
    log_info "Ejecuta primero: ./generate-ssl-certs.sh"
    exit 1
fi

log_info "Certificado encontrado: $CERT_FILE"

# Detectar la distribución Linux
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$NAME
    VER=$VERSION_ID
else
    log_error "No se pudo detectar la distribución Linux"
    exit 1
fi

log_info "Sistema detectado: $OS"

# Función para instalar en Ubuntu/Debian
install_ubuntu_debian() {
    log_info "Instalando certificado para Ubuntu/Debian..."
    
    # Copiar certificado al directorio de certificados locales
    sudo cp "$CERT_FILE" "/usr/local/share/ca-certificates/${CERT_NAME}.crt"
    
    # Actualizar certificados del sistema
    sudo update-ca-certificates
    
    if [ $? -eq 0 ]; then
        log_success "Certificado instalado exitosamente en el sistema"
    else
        log_error "Error al instalar el certificado en el sistema"
        return 1
    fi
}

# Función para instalar en CentOS/RHEL/Fedora
install_redhat() {
    log_info "Instalando certificado para CentOS/RHEL/Fedora..."
    
    # Copiar certificado al directorio de certificados locales
    sudo cp "$CERT_FILE" "/etc/pki/ca-trust/source/anchors/${CERT_NAME}.crt"
    
    # Actualizar certificados del sistema
    sudo update-ca-trust
    
    if [ $? -eq 0 ]; then
        log_success "Certificado instalado exitosamente en el sistema"
    else
        log_error "Error al instalar el certificado en el sistema"
        return 1
    fi
}

# Función para instalar en Arch Linux
install_arch() {
    log_info "Instalando certificado para Arch Linux..."
    
    # Copiar certificado al directorio de certificados locales
    sudo cp "$CERT_FILE" "/etc/ca-certificates/trust-source/anchors/${CERT_NAME}.crt"
    
    # Actualizar certificados del sistema
    sudo trust extract-compat
    
    if [ $? -eq 0 ]; then
        log_success "Certificado instalado exitosamente en el sistema"
    else
        log_error "Error al instalar el certificado en el sistema"
        return 1
    fi
}

# Verificar permisos de sudo
if ! sudo -n true 2>/dev/null; then
    log_warning "Este script requiere permisos de administrador (sudo)"
    log_info "Se te pedirá la contraseña de sudo..."
fi

# Mostrar información del certificado antes de instalar
echo ""
log_info "Información del certificado a instalar:"
echo "  📁 Archivo: $CERT_FILE"
echo "  🏷️  Nombre: $CERT_NAME"
echo ""
echo "  🔍 Dominios incluidos:"
openssl x509 -in "$CERT_FILE" -text -noout | grep -A2 "Subject Alternative Name" | tail -1 | sed 's/^[[:space:]]*/    /'
echo ""
echo "  📅 Validez:"
openssl x509 -in "$CERT_FILE" -noout -dates | sed 's/^/    /'
echo ""

# Confirmar instalación
read -p "¿Deseas instalar este certificado en el sistema? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_warning "Instalación cancelada por el usuario"
    exit 0
fi

# Instalar según la distribución
case "$OS" in
    *"Ubuntu"*|*"Debian"*|*"Linux Mint"*|*"Pop!_OS"*)
        install_ubuntu_debian
        ;;
    *"CentOS"*|*"Red Hat"*|*"Fedora"*|*"Rocky"*|*"AlmaLinux"*)
        install_redhat
        ;;
    *"Arch"*|*"Manjaro"*|*"EndeavourOS"*)
        install_arch
        ;;
    *)
        log_warning "Distribución no reconocida: $OS"
        log_info "Intentando método genérico para Ubuntu/Debian..."
        install_ubuntu_debian
        ;;
esac

echo ""
log_success "¡Certificado instalado exitosamente!"
echo ""

# Instrucciones post-instalación
echo -e "${BLUE}Pasos siguientes:${NC}"
echo ""
echo "1. ${YELLOW}Reinicia tus navegadores${NC} para que reconozcan el nuevo certificado"
echo ""
echo "2. ${YELLOW}Verifica la instalación${NC}:"
echo "   • Navega a: https://nextcloud.net"
echo "   • El navegador NO debería mostrar advertencias de seguridad"
echo "   • Verifica el icono de candado en la barra de direcciones"
echo ""
echo "3. ${YELLOW}Prueba otros subdominios${NC}:"
echo "   • https://www.nextcloud.net"
echo "   • https://admin.nextcloud.net"
echo "   • https://cualquier-nombre.nextcloud.net"
echo ""

# Función para verificar la instalación
verify_installation() {
    log_info "Verificando la instalación del certificado..."
    
    # Verificar que el certificado está en el almacén del sistema
    if openssl verify -CApath /etc/ssl/certs "$CERT_FILE" >/dev/null 2>&1; then
        log_success "✅ Certificado verificado correctamente en el almacén del sistema"
    else
        log_warning "⚠️  El certificado está instalado pero puede necesitar tiempo para propagarse"
    fi
    
    # Verificar conectividad HTTPS sin -k (sin ignorar certificados)
    log_info "Probando conexión HTTPS sin ignorar certificados..."
    if curl -s --connect-timeout 5 https://nextcloud.net >/dev/null 2>&1; then
        log_success "✅ Conexión HTTPS exitosa sin advertencias"
    else
        log_warning "⚠️  La conexión aún puede mostrar advertencias (reinicia el navegador)"
    fi
}

# Preguntar si verificar la instalación
echo ""
read -p "¿Deseas verificar la instalación ahora? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    verify_installation
fi

echo ""
echo -e "${GREEN}=================================================${NC}"
echo -e "${GREEN}  🎉 INSTALACIÓN COMPLETADA${NC}"
echo -e "${GREEN}=================================================${NC}"
echo ""
echo -e "${BLUE}Comandos útiles:${NC}"
echo "  • Verificar certificados del sistema: ${YELLOW}ls /etc/ssl/certs/ | grep nextcloud${NC}"
echo "  • Verificar certificado específico: ${YELLOW}openssl verify -CApath /etc/ssl/certs $CERT_FILE${NC}"
echo "  • Remover certificado (si es necesario): ${YELLOW}./uninstall-ssl-cert.sh${NC}"
echo ""
echo -e "${YELLOW}Nota:${NC} Si aún ves advertencias en el navegador:"
echo "  1. Cierra completamente el navegador"
echo "  2. Ábrelo nuevamente"
echo "  3. Limpia la caché (Ctrl+Shift+Delete)"
echo "  4. Intenta navegar nuevamente a https://nextcloud.net"
echo ""
echo -e "${GREEN}¡Disfruta tu Nextcloud sin advertencias de SSL! 🚀${NC}"