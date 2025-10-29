#!/bin/bash

# Script para generar certificados autofirmados wildcard para nextcloud.net
# Autor: Sistema de generación automática de certificados
# Fecha: $(date +%Y-%m-%d)

set -e  # Salir si hay algún error

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuración
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CERTS_OUTPUT_DIR="$PROJECT_DIR/swag-config/etc/letsencrypt/live/nextcloud.net"
TEMP_CERTS_DIR="$PROJECT_DIR/temp-certs"

echo -e "${BLUE}=================================================${NC}"
echo -e "${BLUE}  Generador de Certificados Autofirmados${NC}"
echo -e "${BLUE}  Dominio: *.nextcloud.net${NC}"
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

# Verificar si Docker está ejecutándose
if ! docker info >/dev/null 2>&1; then
    log_error "Docker no está ejecutándose. Por favor, inicia Docker y vuelve a intentar."
    exit 1
fi

log_info "Docker está ejecutándose correctamente"

# Crear directorio temporal si no existe
if [ ! -d "$TEMP_CERTS_DIR" ]; then
    log_info "Creando directorio temporal: $TEMP_CERTS_DIR"
    mkdir -p "$TEMP_CERTS_DIR"
fi

# Limpiar directorio temporal
log_info "Limpiando directorio temporal..."
rm -rf "$TEMP_CERTS_DIR"/*

# Construir imagen del generador de certificados
log_info "Construyendo imagen del generador de certificados..."
docker build -t nextcloud-cert-generator "$PROJECT_DIR/self-signed-certs/"

if [ $? -ne 0 ]; then
    log_error "Error al construir la imagen Docker"
    exit 1
fi

log_success "Imagen construida exitosamente"

# Generar certificados
log_info "Generando certificados autofirmados wildcard..."
docker run --rm \
    -v "$TEMP_CERTS_DIR:/output" \
    --user "$(id -u):$(id -g)" \
    nextcloud-cert-generator

if [ $? -ne 0 ]; then
    log_error "Error al generar los certificados"
    exit 1
fi

log_success "Certificados generados exitosamente"

# Verificar que los archivos se crearon
if [ ! -f "$TEMP_CERTS_DIR/fullchain.pem" ] || [ ! -f "$TEMP_CERTS_DIR/privkey.pem" ]; then
    log_error "Los archivos de certificado no se generaron correctamente"
    exit 1
fi

# Crear directorio de destino si no existe
log_info "Preparando directorio de destino: $CERTS_OUTPUT_DIR"
mkdir -p "$CERTS_OUTPUT_DIR"

# Hacer backup de certificados existentes si existen
if [ -f "$CERTS_OUTPUT_DIR/fullchain.pem" ]; then
    BACKUP_DIR="$CERTS_OUTPUT_DIR/backup-$(date +%Y%m%d-%H%M%S)"
    log_info "Creando backup de certificados existentes en: $BACKUP_DIR"
    mkdir -p "$BACKUP_DIR"
    cp "$CERTS_OUTPUT_DIR"/*.pem "$BACKUP_DIR/" 2>/dev/null || true
    log_success "Backup creado"
fi

# Copiar certificados al directorio de destino
log_info "Copiando certificados al directorio de nginx..."
cp "$TEMP_CERTS_DIR/fullchain.pem" "$CERTS_OUTPUT_DIR/"
cp "$TEMP_CERTS_DIR/privkey.pem" "$CERTS_OUTPUT_DIR/"
cp "$TEMP_CERTS_DIR/cert.pem" "$CERTS_OUTPUT_DIR/"

# Establecer permisos correctos
chmod 644 "$CERTS_OUTPUT_DIR/fullchain.pem"
chmod 644 "$CERTS_OUTPUT_DIR/cert.pem"
chmod 600 "$CERTS_OUTPUT_DIR/privkey.pem"

log_success "Certificados copiados con permisos correctos"

# Limpiar directorio temporal
log_info "Limpiando archivos temporales..."
rm -rf "$TEMP_CERTS_DIR"

# Mostrar información de los certificados
echo ""
echo -e "${GREEN}=================================================${NC}"
echo -e "${GREEN}  CERTIFICADOS GENERADOS EXITOSAMENTE${NC}"
echo -e "${GREEN}=================================================${NC}"
echo ""
echo -e "${BLUE}Ubicación de los certificados:${NC}"
echo "  📁 $CERTS_OUTPUT_DIR"
echo ""
echo -e "${BLUE}Archivos generados:${NC}"
echo "  🔐 fullchain.pem (certificado completo)"
echo "  🔑 privkey.pem (clave privada)"
echo "  📜 cert.pem (certificado)"
echo ""

# Mostrar información del certificado
echo -e "${BLUE}Información del certificado:${NC}"
openssl x509 -in "$CERTS_OUTPUT_DIR/fullchain.pem" -text -noout | grep -A1 "Subject:" | sed 's/^/  /'
echo ""
echo -e "${BLUE}Dominios incluidos:${NC}"
openssl x509 -in "$CERTS_OUTPUT_DIR/fullchain.pem" -text -noout | grep -A10 "Subject Alternative Name" | sed 's/^/  /'
echo ""
echo -e "${BLUE}Validez del certificado:${NC}"
openssl x509 -in "$CERTS_OUTPUT_DIR/fullchain.pem" -noout -dates | sed 's/^/  /'

echo ""
echo -e "${YELLOW}Siguiente paso:${NC}"
echo "  1. Reinicia el contenedor nginx-proxy para cargar los nuevos certificados:"
echo "     ${BLUE}docker-compose restart nginx-proxy${NC}"
echo ""
echo "  2. O reinicia todo el stack:"
echo "     ${BLUE}docker-compose down && docker-compose up -d${NC}"
echo ""
echo -e "${YELLOW}Nota:${NC} Los certificados son autofirmados. Tu navegador mostrará una advertencia de seguridad."
echo "      Para uso en desarrollo local, puedes aceptar la advertencia o instalar el certificado"
echo "      en el almacén de certificados de confianza de tu sistema operativo."
echo ""
echo -e "${GREEN}¡Proceso completado exitosamente!${NC}"