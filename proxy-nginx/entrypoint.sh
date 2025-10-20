# /docker-entrypoint.d/99-generate-cert.sh
CERT_DIR="/etc/nginx/certs/nextcloud.net"
if [[ -f "$CERT_DIR/fullchain.pem" && -f "$CERT_DIR/privkey.pem" ]]; then
  echo "✅ [entrypoint] Certs montados; no genero."
  exit 0
fi
# (solo si faltan, genera en ese MISMO path)
mkdir -p "$CERT_DIR"
openssl req -x509 -nodes -newkey rsa:4096 -days 825 \
  -keyout "$CERT_DIR/privkey.pem" \
  -out    "$CERT_DIR/fullchain.pem" \
  -subj "/CN=*.nextcloud.net" \
  -addext "subjectAltName=DNS:nextcloud.net,DNS:*.nextcloud.net"
