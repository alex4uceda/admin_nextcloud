#!/bin/sh
set -eu

CERT_DIR="/etc/nginx/certs/nextcloud.net"
CERT="$CERT_DIR/fullchain.pem"
KEY="$CERT_DIR/privkey.pem"

echo "🔐 [entrypoint] Verificando certificados en $CERT_DIR ..."
if [ -f "$CERT" ] && [ -f "$KEY" ]; then
  echo "✅ [entrypoint] Certificados existentes detectados. No se generará nada."
  exit 0
fi

echo "❌ [entrypoint] No hay certificados en $CERT_DIR."
echo "   Este contenedor espera que montes los .pem (solo lectura) desde SWAG:"
echo "   ./swag-config/etc/letsencrypt/live/nextcloud.net -> $CERT_DIR:ro"
echo "   Aborto para evitar escribir sobre un volumen de solo lectura."
exit 1
