#!/bin/bash

echo "🔐 [entrypoint] Verificando certificados..."

# Si existen certificados de Let's Encrypt, ajustar permisos y no hacer nada más
if ls /etc/nginx/certs/*.pem 1> /dev/null 2>&1 && ls /etc/nginx/private/*.key 1> /dev/null 2>&1; then
    echo "✅ [entrypoint] Certificados de Let's Encrypt encontrados. Ajustando permisos."
    chmod 644 /etc/nginx/certs/*.pem
    chmod 600 /etc/nginx/private/*.key
else
    echo "📄 [entrypoint] No se encontraron certificados válidos. Generando autofirmado..."
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/nginx/private/cert_default.key \
        -out /etc/nginx/certs/cert_default.pem \
        -subj "/CN=default"
    chmod 644 /etc/nginx/certs/cert_default.pem
    chmod 600 /etc/nginx/private/cert_default.key
    echo "✅ [entrypoint] Certificado autofirmado generado."
fi