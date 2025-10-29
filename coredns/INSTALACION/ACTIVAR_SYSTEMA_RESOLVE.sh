#!/bin/bash

set -e

echo "🛠️ Restaurando configuración original del sistema DNS..."

if [ -f /etc/resolv.conf ]; then
    echo "🔓 Quitando protección inmutable (si aplica)..."
    sudo chattr -i /etc/resolv.conf || true
    sudo rm -f /etc/resolv.conf
fi

echo "🔗 Creando symlink a stub resolver de systemd..."
sudo ln -s /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

echo "🚀 Habilitando y arrancando systemd-resolved..."
sudo systemctl enable systemd-resolved
sudo systemctl start systemd-resolved

echo "⌛ Esperando 3 segundos para estabilización..."
sleep 3

echo "🔎 Verificando estado de systemd-resolved..."
sudo systemctl status systemd-resolved --no-pager

echo "🧪 Probando resolución DNS con dig (usando 127.0.0.53)..."
for domain in google.com microsoft.com ubuntu.com; do
    echo "🔎 Resolviendo $domain..."
    dig "$domain" @127.0.0.53 | grep -E "ANSWER SECTION|status:|;; Query time:"
done

echo "✅ DNS del sistema restaurado correctamente y systemd-resolved activo."
