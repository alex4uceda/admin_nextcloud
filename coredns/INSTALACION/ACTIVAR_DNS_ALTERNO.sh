#!/bin/bash

set -e

echo "🛑 Deteniendo y deshabilitando systemd-resolved..."
sudo systemctl stop systemd-resolved
sudo systemctl disable systemd-resolved

echo "🧹 Eliminando symlink de /etc/resolv.conf si existe..."
if [ -L /etc/resolv.conf ]; then
    sudo rm /etc/resolv.conf
fi

echo "📄 Creando nuevo /etc/resolv.conf con DNS primario 192.168.11.10 y secundario público..."
echo -e "nameserver 192.168.11.10\nnameserver 1.1.1.1" | sudo tee /etc/resolv.conf

echo "✅ Verificación del contenido de /etc/resolv.conf:"
cat /etc/resolv.conf

echo "🔁 Probando resolución de rh.local..."
dig rh.local

echo "🌐 Probando conexión HTTP a http://bomba.rh.local"
curl -v http://bomba.rh.local || echo "⚠️ Error accediendo al dominio"

echo "✅ DNS configurado correctamente para usar 192.168.11.10 como primario."
