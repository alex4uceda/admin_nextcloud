#!/bin/bash

set -e

echo "🛑 Desactivando systemd-resolved..."
sudo systemctl stop systemd-resolved
sudo systemctl disable systemd-resolved

echo "🔄 Borrando symlink de /etc/resolv.conf si existe..."
if [ -L /etc/resolv.conf ]; then
    sudo rm /etc/resolv.conf
fi

echo "📄 Creando nuevo /etc/resolv.conf apuntando al DNS de Docker..."
echo "nameserver 127.0.0.1" | sudo tee /etc/resolv.conf

echo "🔎 Verificando que el puerto 53 esté libre..."
if lsof -i :53; then
    echo "⚠️  Puerto 53 aún está en uso. Abortando."
    exit 1
else
    echo "✅ Puerto 53 libre."
fi

echo "🚀 Verificando si el contenedor coredns está corriendo..."
if ! docker ps --format '{{.Names}}' | grep -q '^coredns$'; then
    echo "🛠️  Iniciando contenedor coredns..."
    docker compose up -d coredns
else
    echo "✅ Contenedor coredns ya está corriendo."
fi

echo "⌛ Esperando 3 segundos para que el DNS arranque..."
sleep 3

echo "🧪 Probando resolución DNS usando dig contra 127.0.0.1..."
for domain in google.com microsoft.com ubuntu.com; do
    echo "🔎 Resolviendo $domain..."
    dig "$domain" @127.0.0.1 | grep -E "ANSWER SECTION|status:|;; Query time:"
done

echo "✅ DNS local funcionando correctamente y systemd-resolved desactivado."
echo "🎉 Proceso de desactivación y configuración DNS completado."