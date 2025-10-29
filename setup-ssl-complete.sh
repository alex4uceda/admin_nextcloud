#!/bin/bash

# Script completo para generar certificados SSL y reiniciar servicios
# Este script automatiza todo el proceso de generación e instalación

set -e

# Colores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}=================================================${NC}"
echo -e "${BLUE}  Setup Completo de Certificados SSL${NC}"
echo -e "${BLUE}  Nextcloud con Docker Compose${NC}"
echo -e "${BLUE}=================================================${NC}"
echo ""

# Verificar que estamos en el directorio correcto
if [ ! -f "docker-compose.yml" ]; then
    echo -e "${RED}Error: No se encontró docker-compose.yml. Ejecuta este script desde el directorio del proyecto.${NC}"
    exit 1
fi

echo -e "${BLUE}Paso 1:${NC} Generando certificados SSL autofirmados..."
./generate-ssl-certs.sh

echo ""
echo -e "${BLUE}Paso 2:${NC} Reiniciando servicios Docker..."

# Verificar si los contenedores están ejecutándose
if docker compose ps | grep -q "Up"; then
    echo "  ↻ Reiniciando nginx-proxy para cargar nuevos certificados..."
    docker compose restart nginx-proxy
    
    echo "  ⏳ Esperando que nginx-proxy se reinicie..."
    sleep 5
    
    # Verificar que nginx-proxy esté ejecutándose
    if docker compose ps nginx-proxy | grep -q "Up"; then
        echo -e "  ${GREEN}✅ nginx-proxy reiniciado exitosamente${NC}"
    else
        echo -e "  ${YELLOW}⚠️  nginx-proxy no está ejecutándose. Iniciando servicios...${NC}"
        docker compose up -d
    fi
else
    echo "  🚀 Los servicios no están ejecutándose. Iniciando stack completo..."
    docker compose up -d
fi

echo ""
echo -e "${BLUE}Paso 3:${NC} Verificando servicios..."

# Esperar un momento para que los servicios se inicien
sleep 5

# Verificar servicios
echo "  🔍 Estado de los servicios:"
docker compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"

echo ""
echo -e "${BLUE}Paso 4:${NC} Verificación de SSL..."

# Función para verificar SSL
verify_ssl() {
    local domain=$1
    echo -n "  🔐 Verificando $domain... "
    
    if curl -k -s --connect-timeout 5 "https://$domain" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ OK${NC}"
    else
        echo -e "${YELLOW}⚠️  No disponible${NC}"
    fi
}

# Verificar dominios
verify_ssl "nextcloud.net"
verify_ssl "www.nextcloud.net"

echo ""
echo -e "${GREEN}=================================================${NC}"
echo -e "${GREEN}  🎉 SETUP COMPLETADO EXITOSAMENTE${NC}"
echo -e "${GREEN}=================================================${NC}"
echo ""
echo -e "${BLUE}Accesos disponibles:${NC}"
echo "  🌐 https://nextcloud.net"
echo "  🌐 https://www.nextcloud.net"
echo "  🌐 https://*.nextcloud.net (cualquier subdominio)"
echo ""
echo -e "${YELLOW}Notas importantes:${NC}"
echo "  • Los certificados son autofirmados (tu navegador mostrará advertencia)"
echo "  • Para eliminar advertencias, instala el certificado en tu sistema"
echo "  • Los certificados tienen validez de 10 años"
echo ""
echo -e "${BLUE}Comandos útiles:${NC}"
echo "  • Ver logs de nginx: ${YELLOW}docker compose logs nginx-proxy${NC}"
echo "  • Reiniciar servicios: ${YELLOW}docker compose restart${NC}"
echo "  • Ver certificado: ${YELLOW}openssl x509 -in swag-config/etc/letsencrypt/live/nextcloud.net/fullchain.pem -text -noout${NC}"
echo ""
echo -e "${GREEN}¡Disfruta tu Nextcloud con SSL! 🚀${NC}"