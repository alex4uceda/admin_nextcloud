#!/bin/bash

set -euo pipefail

DNS_IP="127.0.0.1"
DNS_PORT="53"
CONTAINER_NAME="coredns"
DOMAINS=(
    "desktop.googleapis.com"
    "ocsp.pki.goog"
    "dns.google"
    "m.google.com"
    "clients4.google.com"
    "google.com"
    "play.googleapis.com"
    "googleapis.com"
    "connectivitycheck.gstatic.com"
    "ssl.gstatic.com"
    # Dominios críticos para Windows
    "windowsupdate.microsoft.com"
    "login.live.com"
    "msftconnecttest.com"
    "www.bing.com"
    "www.microsoft.com"
    # Dominios críticos para Linux
    "archive.ubuntu.com"
    "security.ubuntu.com"
    "repo.linuxmint.com"
    "pool.ntp.org"
    # Otros de uso común
    "github.com"
    "api.github.com"
    "facebook.com"
    "twitter.com"
    "youtube.com"
)
RECORD_TYPES=("A" "AAAA" "MX" "CNAME" "TXT")



echo "🧪 Iniciando pruebas de resolución DNS..."
for domain in "${DOMAINS[@]}"; do
    echo "🔎 Dominio: $domain"
    for record in "${RECORD_TYPES[@]}"; do
        echo "  📥 Consultando tipo $record..."
        result=$(dig @$DNS_IP -p $DNS_PORT "$domain" $record +time=2 +tries=2 +short)
        if [[ -z "$result" ]]; then
            echo "  ❌ ERROR: No se resolvió $domain ($record)"
        else
            echo "  ✅ Resuelto ($record):"
            echo "$result" | sed 's/^/     • /'
        fi
    done
    echo ""
done

echo "⏱️ Midiendo tiempo de respuesta promedio..."
for domain in "${DOMAINS[@]}"; do
    query_time=$(dig @$DNS_IP -p $DNS_PORT "$domain" +stats | grep "Query time" | awk '{print $4}')
    echo "🔸 $domain → ${query_time}ms"
done

echo "📄 Revisando logs recientes del contenedor ($CONTAINER_NAME)..."
docker logs --tail 10 $CONTAINER_NAME || echo "⚠️ No hay logs recientes."

echo "🎯 Pruebas de DNS finalizadas exitosamente."
