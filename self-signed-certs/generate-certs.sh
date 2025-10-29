#!/bin/sh

# Configuración
DOMAIN="nextcloud.net"
CERT_DIR="/output"
DAYS=3650  # 10 años

echo "Generando certificados autofirmados wildcard para *.$DOMAIN"

# Crear directorios si no existen
mkdir -p "$CERT_DIR"

# Crear archivo de configuración OpenSSL para certificado wildcard
cat > /tmp/openssl.conf << EOF
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no

[req_distinguished_name]
C=SV
ST=San Salvador
L=San Salvador
O=Nextcloud Local
OU=IT Department
CN=*.$DOMAIN

[v3_req]
keyUsage = keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = $DOMAIN
DNS.2 = *.$DOMAIN
DNS.3 = www.$DOMAIN
EOF

# Generar clave privada
echo "Generando clave privada..."
openssl genrsa -out "$CERT_DIR/privkey.pem" 2048

# Generar certificado autofirmado
echo "Generando certificado autofirmado..."
openssl req -new -x509 -key "$CERT_DIR/privkey.pem" -out "$CERT_DIR/fullchain.pem" -days $DAYS -config /tmp/openssl.conf -extensions v3_req

# Crear una copia del certificado como cert.pem (para compatibilidad)
cp "$CERT_DIR/fullchain.pem" "$CERT_DIR/cert.pem"

# Mostrar información del certificado
echo "Certificado generado exitosamente!"
echo "Archivos creados:"
echo "- $CERT_DIR/privkey.pem (clave privada)"
echo "- $CERT_DIR/fullchain.pem (certificado completo)"
echo "- $CERT_DIR/cert.pem (certificado)"

echo ""
echo "Información del certificado:"
openssl x509 -in "$CERT_DIR/fullchain.pem" -text -noout | grep -A1 "Subject:"
openssl x509 -in "$CERT_DIR/fullchain.pem" -text -noout | grep -A10 "Subject Alternative Name"

echo ""
echo "Validez del certificado:"
openssl x509 -in "$CERT_DIR/fullchain.pem" -noout -dates

# Cambiar permisos
chmod 644 "$CERT_DIR"/*.pem
chmod 600 "$CERT_DIR/privkey.pem"

echo ""
echo "¡Certificados generados correctamente!"