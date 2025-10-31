#!/bin/bash
# Script para verificar el estado de la automatización en los contenedores

echo "🔍 Verificando automatización de escritorios XFCE..."
echo "=================================================="

# Función para verificar un contenedor
check_container() {
    local container_name=$1
    local port=$2
    
    echo ""
    echo "📋 Verificando $container_name:"
    
    if docker ps | grep -q "$container_name"; then
        echo "   ✅ Estado: EJECUTÁNDOSE"
        
        # Verificar si el script de configuración se ejecutó
        if docker exec "$container_name" test -f /home/headless/Desktop/INFO_SISTEMA.txt 2>/dev/null; then
            echo "   ✅ Automatización: COMPLETADA"
            echo "   📄 Archivo de información: CREADO"
        else
            echo "   ⏳ Automatización: EN PROGRESO (espera unos segundos)"
        fi
        
        # Verificar navegadores
        echo "   🌐 Navegadores:"
        if docker exec "$container_name" which firefox >/dev/null 2>&1; then
            echo "      ✅ Firefox: INSTALADO"
        else
            echo "      ❌ Firefox: NO ENCONTRADO"
        fi
        
        if docker exec "$container_name" which chromium-browser >/dev/null 2>&1; then
            echo "      ✅ Chromium: INSTALADO"
        else
            echo "      ❌ Chromium: NO ENCONTRADO"
        fi
        
        # Verificar accesos directos
        local desktop_files=$(docker exec "$container_name" ls /home/headless/Desktop/*.desktop 2>/dev/null | wc -l)
        if [ "$desktop_files" -gt 0 ]; then
            echo "   🖥️  Accesos directos: $desktop_files CREADOS"
        else
            echo "   ⏳ Accesos directos: CREANDO..."
        fi
        
        echo "   🌐 Acceso web: http://localhost:$port"
        
    else
        echo "   ❌ Estado: NO EJECUTÁNDOSE"
        echo "   🚀 Para iniciar: docker compose up -d $container_name"
    fi
}

# Verificar ambos contenedores
check_container "xfce-desktop-a" "6901"
check_container "xfce-desktop-b" "6902"

echo ""
echo "=================================================="
echo "💡 Consejos:"
echo "   • La automatización toma 5-10 segundos después del inicio"
echo "   • Accede via web browser para mejor experiencia"
echo "   • Revisa INFO_SISTEMA.txt en el escritorio para más detalles"
echo ""
echo "🔄 Para volver a verificar: ./verify-automation.sh"