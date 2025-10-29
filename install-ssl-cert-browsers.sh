#!/bin/bash

# Script adicional para instalar certificado en navegadores específicos
# Especialmente útil para Firefox que usa su propio almacén de certificados

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CERT_FILE="$PROJECT_DIR/swag-config/etc/letsencrypt/live/nextcloud.net/fullchain.pem"

echo -e "${BLUE}=================================================${NC}"
echo -e "${BLUE}  Instalador de Certificado para Navegadores${NC}"
echo -e "${BLUE}  Configuración adicional${NC}"
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

# Verificar que el certificado existe
if [ ! -f "$CERT_FILE" ]; then
    echo -e "${RED}[ERROR]${NC} Certificado no encontrado en: $CERT_FILE"
    echo -e "${BLUE}[INFO]${NC} Ejecuta primero: ./generate-ssl-certs.sh"
    exit 1
fi

echo -e "${GREEN}🎯 INSTRUCCIONES MANUALES PARA NAVEGADORES${NC}"
echo ""

# Instrucciones para Chrome/Chromium/Edge
echo -e "${BLUE}📱 CHROME / CHROMIUM / MICROSOFT EDGE:${NC}"
echo "  1. Abre el navegador y ve a: chrome://settings/certificates"
echo "  2. Haz clic en la pestaña 'Autoridades'"
echo "  3. Haz clic en 'Importar'"
echo "  4. Selecciona el archivo: $CERT_FILE"
echo "  5. Marca todas las casillas de confianza"
echo "  6. Haz clic en 'Aceptar'"
echo ""

# Instrucciones para Firefox
echo -e "${BLUE}🦊 FIREFOX:${NC}"
echo "  1. Abre Firefox y ve a: about:preferences#privacy"
echo "  2. Busca 'Certificados' y haz clic en 'Ver certificados'"
echo "  3. Ve a la pestaña 'Autoridades'"
echo "  4. Haz clic en 'Importar'"
echo "  5. Selecciona el archivo: $CERT_FILE"
echo "  6. Marca 'Confiar en esta CA para identificar sitios web'"
echo "  7. Haz clic en 'Aceptar'"
echo ""

# Instrucciones alternativas para Firefox usando certutil
if command -v certutil >/dev/null 2>&1; then
    echo -e "${BLUE}🔧 FIREFOX (Método Automático):${NC}"
    echo "  Se detectó certutil. ¿Deseas instalar automáticamente en Firefox?"
    read -p "  (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Buscar perfiles de Firefox
        FIREFOX_PROFILES=""
        if [ -d "$HOME/.mozilla/firefox" ]; then
            FIREFOX_PROFILES=$(find "$HOME/.mozilla/firefox" -name "*.default*" -type d 2>/dev/null)
        fi
        
        if [ -n "$FIREFOX_PROFILES" ]; then
            log_info "Instalando certificado en perfiles de Firefox..."
            for profile in $FIREFOX_PROFILES; do
                if [ -f "$profile/cert9.db" ]; then
                    log_info "Instalando en perfil: $(basename "$profile")"
                    certutil -A -n "Nextcloud Local CA" -t "TCu,Cu,Tu" -i "$CERT_FILE" -d sql:"$profile" 2>/dev/null || true
                fi
            done
            log_success "Certificado instalado en Firefox"
        else
            log_warning "No se encontraron perfiles de Firefox"
        fi
    fi
else
    echo -e "${YELLOW}💡 TIP:${NC} Para instalación automática en Firefox:"
    echo "   sudo apt install libnss3-tools  # Ubuntu/Debian"
    echo "   sudo dnf install nss-tools      # Fedora"
    echo "   sudo pacman -S nss              # Arch Linux"
fi

echo ""

# Crear un archivo .desktop para fácil acceso
DESKTOP_FILE="$HOME/Desktop/Nextcloud-SSL-Certificate.desktop"
cat > "$DESKTOP_FILE" << EOF
[Desktop Entry]
Version=1.0
Type=Link
Name=Certificado SSL Nextcloud
Comment=Certificado SSL para instalar en navegadores
Icon=security-high
URL=file://$CERT_FILE
EOF

if [ -f "$DESKTOP_FILE" ]; then
    chmod +x "$DESKTOP_FILE"
    log_success "Acceso directo creado en el escritorio"
fi

# Copiar certificado a una ubicación más accesible
USER_CERT_DIR="$HOME/Documentos/Certificados-SSL"
mkdir -p "$USER_CERT_DIR"
cp "$CERT_FILE" "$USER_CERT_DIR/nextcloud-local-certificate.pem"
log_success "Certificado copiado a: $USER_CERT_DIR/nextcloud-local-certificate.pem"

echo ""
echo -e "${GREEN}📋 RESUMEN DE ARCHIVOS CREADOS:${NC}"
echo "  🔐 Certificado original: $CERT_FILE"
echo "  📁 Copia para usuario: $USER_CERT_DIR/nextcloud-local-certificate.pem"
echo "  🖥️  Acceso directo: $DESKTOP_FILE"
echo ""

echo -e "${YELLOW}🔄 PASOS DESPUÉS DE LA INSTALACIÓN:${NC}"
echo "  1. Cierra completamente todos los navegadores"
echo "  2. Ábrelos nuevamente"
echo "  3. Limpia la caché del navegador (Ctrl+Shift+Delete)"
echo "  4. Navega a https://nextcloud.net"
echo "  5. Verifica que NO aparezcan advertencias de seguridad"
echo ""

echo -e "${BLUE}🧪 VERIFICACIÓN RÁPIDA:${NC}"
echo "  Ejecuta este comando para verificar la instalación del sistema:"
echo "  ${YELLOW}curl https://nextcloud.net${NC}"
echo ""
echo "  Si NO muestra errores de SSL, el certificado está correctamente instalado."
echo ""

echo -e "${GREEN}¡Certificado listo para instalar en navegadores! 🎉${NC}"