#!/bin/bash
# Script to access XFCE Desktop with browsers

echo "==========================================="
echo "XFCE Desktop with Browsers - Access Info"
echo "==========================================="

# Check XFCE Desktop A
echo "🖥️  XFCE Desktop A:"
if docker compose ps xfce-desktop-a | grep -q "Up"; then
    echo "   ✅ Status: RUNNING"
    
    # Get container IP A
    CONTAINER_IP_A=$(docker inspect xfce-desktop-a | grep '"IPAddress"' | tail -1 | sed 's/.*"IPAddress": "\([^"]*\)".*/\1/')
    
    echo "   🌐 Web Access (noVNC):   http://localhost:6901"
    echo "   🌐 Web Access (IP):      http://$CONTAINER_IP_A:6901"
    echo "   🖥️  VNC Client:          localhost:5901"
    echo "   📁 Workspace:            ./dataA"
else
    echo "   ❌ Status: NOT RUNNING"
    echo "   🚀 Start: docker compose up -d xfce-desktop-a"
fi

echo ""

# Check XFCE Desktop B
echo "🖥️  XFCE Desktop B:"
if docker compose ps xfce-desktop-b | grep -q "Up"; then
    echo "   ✅ Status: RUNNING"
    
    # Get container IP B
    CONTAINER_IP_B=$(docker inspect xfce-desktop-b | grep '"IPAddress"' | tail -1 | sed 's/.*"IPAddress": "\([^"]*\)".*/\1/')
    
    echo "   🌐 Web Access (noVNC):   http://localhost:6902"
    echo "   🌐 Web Access (IP):      http://$CONTAINER_IP_B:6902"
    echo "   🖥️  VNC Client:          localhost:5902"
    echo "   📁 Workspace:            ./dataB"
else
    echo "   ❌ Status: NOT RUNNING"
    echo "   🚀 Start: docker compose up -d xfce-desktop-b"
fi

echo ""
echo "🔑 VNC Password (both): MiPasswordFuerte123"
echo ""
echo "🌐 Installed Browsers & Tools (both desktops):"
echo "   • Firefox - Navegador completo"
echo "   • Chromium - Navegador de código abierto"
echo "   • Terminal - xfce4-terminal"
echo "   • Editor - mousepad"
echo "   • Explorador - thunar"
echo ""
echo "🤖 Automatización:"
echo "   • ✅ Configuración automática al crear contenedor"
echo "   • ✅ Accesos directos creados automáticamente"
echo "   • ✅ Navegadores optimizados para contenedores"
echo "   • ✅ Archivo INFO_SISTEMA.txt en escritorio"
echo ""
echo "💡 Tips:"
echo "   • Use web browser access for easiest setup"
echo "   • Click on browser icons on desktop to launch"
echo "   • Files saved in workspace will persist"
echo "   • Each desktop has independent workspace"
echo "   • Check INFO_SISTEMA.txt on desktop for details"
echo ""
echo "🚀 Start both desktops:"
echo "   docker compose up -d xfce-desktop-a xfce-desktop-b"

echo "==========================================="