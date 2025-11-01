#!/bin/bash

# ===================================================================================
# GENERADOR DE CERTIFICADOS SSL PARA MARIADB
# ===================================================================================
# 
# Este script genera certificados SSL para MariaDB incluyendo:
# - Certificado de Autoridad Certificadora (CA)
# - Certificado del servidor MariaDB
# - Certificado del cliente para conexiones encriptadas
#
# Los certificados se generan con una validez de 10 años
# ===================================================================================

set -e

# Configuración
SSL_DIR="$(pwd)/ssl-certs/mariadb"
DAYS=3650  # 10 años
COUNTRY="SV"
STATE="San_Salvador"
CITY="San_Salvador"
ORG="Nextcloud_Backup"
OU="Database_SSL"

echo "=== GENERANDO CERTIFICADOS SSL PARA MARIADB ==="

# Limpiar certificados anteriores
rm -rf "$SSL_DIR"
mkdir -p "$SSL_DIR"
cd "$SSL_DIR"

echo "Directorio de trabajo: $SSL_DIR"

# 1. Generar llave privada para CA
echo "1. Generando llave privada del CA..."
openssl genrsa 2048 > ca-key.pem

# 2. Generar certificado del CA
echo "2. Generando certificado del CA..."
openssl req -new -x509 -nodes -days $DAYS -key ca-key.pem -out ca.pem \
    -subj "/C=$COUNTRY/ST=$STATE/L=$CITY/O=$ORG/OU=${OU}_CA/CN=MariaDB_CA"

# 3. Generar llave privada del servidor
echo "3. Generando llave privada del servidor..."
openssl req -newkey rsa:2048 -days $DAYS -nodes -keyout server-key.pem -out server-req.pem \
    -subj "/C=$COUNTRY/ST=$STATE/L=$CITY/O=$ORG/OU=${OU}_Server/CN=db"

# 4. Procesar llave del servidor
echo "4. Procesando llave del servidor..."
openssl rsa -in server-key.pem -out server-key.pem

# 5. Generar certificado del servidor
echo "5. Generando certificado del servidor..."
openssl x509 -req -in server-req.pem -days $DAYS -CA ca.pem -CAkey ca-key.pem -set_serial 01 -out server-cert.pem

# 6. Generar llave privada del cliente
echo "6. Generando llave privada del cliente..."
openssl req -newkey rsa:2048 -days $DAYS -nodes -keyout client-key.pem -out client-req.pem \
    -subj "/C=$COUNTRY/ST=$STATE/L=$CITY/O=$ORG/OU=${OU}_Client/CN=nextcloud-backup"

# 7. Procesar llave del cliente
echo "7. Procesando llave del cliente..."
openssl rsa -in client-key.pem -out client-key.pem

# 8. Generar certificado del cliente
echo "8. Generando certificado del cliente..."
openssl x509 -req -in client-req.pem -days $DAYS -CA ca.pem -CAkey ca-key.pem -set_serial 02 -out client-cert.pem

# Limpiar archivos temporales
rm -f server-req.pem client-req.pem

# Configurar permisos
chmod 600 *-key.pem
chmod 644 *.pem

echo ""
echo "=== CERTIFICADOS GENERADOS EXITOSAMENTE ==="
echo "Ubicación: $SSL_DIR"
echo ""
echo "Archivos generados:"
ls -la "$SSL_DIR"
echo ""
echo "Certificados listos para usar con MariaDB y clientes SSL"

# Verificar certificados
echo ""
echo "=== VERIFICACIÓN DE CERTIFICADOS ==="
echo "Verificando certificado del servidor..."
openssl verify -CAfile ca.pem server-cert.pem

echo "Verificando certificado del cliente..."
openssl verify -CAfile ca.pem client-cert.pem

echo ""
echo "¡Certificados SSL generados y verificados correctamente!"