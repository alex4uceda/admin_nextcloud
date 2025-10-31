#!/bin/bash
# Script de inicialización automática para XFCE Desktop con navegadores
# Se ejecuta automáticamente al crear/iniciar el contenedor

set -e

echo "🚀 Iniciando configuración automática del escritorio..."

# Función para configurar escritorio
setup_desktop() {
    local user_home="/home/headless"
    local desktop_dir="$user_home/Desktop"
    
    echo "📁 Configurando directorio del escritorio..."
    mkdir -p "$desktop_dir"
    
    # Crear accesos directos para navegadores
    echo "🌐 Creando accesos directos de navegadores..."
    
    # Firefox
    cat > "$desktop_dir/Firefox.desktop" << 'EOF'
[Desktop Entry]
Version=1.0
Name=Firefox
Comment=Navegador Web
Exec=firefox %u
Icon=firefox
Terminal=false
Type=Application
Categories=Network;WebBrowser;
StartupNotify=true
EOF

    # Chromium
    cat > "$desktop_dir/Chromium.desktop" << 'EOF'
[Desktop Entry]
Version=1.0
Name=Chromium
Comment=Navegador Web de Código Abierto
Exec=chromium-browser --no-sandbox %U
Icon=chromium-browser
Terminal=false
Type=Application
Categories=Network;WebBrowser;
StartupNotify=true
EOF

    # Terminal
    cat > "$desktop_dir/Terminal.desktop" << 'EOF'
[Desktop Entry]
Version=1.0
Name=Terminal
Comment=Terminal del Sistema
Exec=xfce4-terminal
Icon=terminal
Terminal=false
Type=Application
Categories=System;TerminalEmulator;
EOF

    # Editor de texto
    cat > "$desktop_dir/Editor.desktop" << 'EOF'
[Desktop Entry]
Version=1.0
Name=Editor de Texto
Comment=Editor de Texto Simple
Exec=mousepad
Icon=mousepad
Terminal=false
Type=Application
Categories=Utility;TextEditor;
EOF

    # Explorador de archivos
    cat > "$desktop_dir/Files.desktop" << 'EOF'
[Desktop Entry]
Version=1.0
Name=Explorador de Archivos
Comment=Gestor de Archivos
Exec=thunar
Icon=file-manager
Terminal=false
Type=Application
Categories=System;FileManager;
EOF

    # Establecer permisos
    chmod +x "$desktop_dir"/*.desktop
    
    # Cambiar propietario si es necesario
    if [ "$(id -u)" = "0" ]; then
        chown -R headless:headless "$desktop_dir" 2>/dev/null || true
    fi
    
    echo "✅ Accesos directos creados exitosamente"
}

# Función para configurar navegadores
setup_browsers() {
    echo "🔧 Configurando navegadores..."
    
    # Crear directorio de configuración para Firefox
    local firefox_config="/home/headless/.mozilla/firefox"
    mkdir -p "$firefox_config"
    
    # Crear perfil por defecto para Firefox
    cat > "$firefox_config/profiles.ini" << 'EOF'
[General]
StartWithLastProfile=1

[Profile0]
Name=default
IsRelative=1
Path=default.default
Default=1
EOF

    # Crear configuración básica de Chromium para evitar errores de sandbox
    local chromium_config="/home/headless/.config/chromium/Default"
    mkdir -p "$chromium_config"
    
    # Configurar Chromium para funcionar en contenedor
    cat > "$chromium_config/Preferences" << 'EOF'
{
   "browser": {
      "check_default_browser": false
   },
   "profile": {
      "default_content_setting_values": {
         "notifications": 2
      },
      "exit_type": "Normal"
   }
}
EOF

    # Cambiar propietario
    if [ "$(id -u)" = "0" ]; then
        chown -R headless:headless /home/headless/.mozilla 2>/dev/null || true
        chown -R headless:headless /home/headless/.config 2>/dev/null || true
    fi
    
    echo "✅ Navegadores configurados"
}

# Función para configurar tema del escritorio
setup_desktop_theme() {
    echo "🎨 Configurando tema del escritorio..."
    
    local xfce_config="/home/headless/.config/xfce4"
    mkdir -p "$xfce_config/xfconf/xfce-perchannel-xml"
    
    # Configurar fondo de pantalla y tema
    cat > "$xfce_config/xfconf/xfce-perchannel-xml/xfce4-desktop.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-desktop" version="1.0">
  <property name="backdrop" type="empty">
    <property name="screen0" type="empty">
      <property name="monitorVNC-0" type="empty">
        <property name="workspace0" type="empty">
          <property name="color-style" type="int" value="0"/>
          <property name="image-style" type="int" value="5"/>
          <property name="last-image" type="string" value="/usr/share/pixmaps/xfce-blue.jpg"/>
        </property>
      </property>
    </property>
  </property>
</channel>
EOF

    # Cambiar propietario
    if [ "$(id -u)" = "0" ]; then
        chown -R headless:headless "$xfce_config" 2>/dev/null || true
    fi
    
    echo "✅ Tema configurado"
}

# Función para crear archivo de información del sistema
create_system_info() {
    echo "📄 Creando archivo de información del sistema..."
    
    cat > "/home/headless/Desktop/INFO_SISTEMA.txt" << EOF
🖥️  INFORMACIÓN DEL ESCRITORIO XFCE
=====================================

📅 Configurado automáticamente el: $(date)

🌐 NAVEGADORES INSTALADOS:
• Firefox        - Navegador completo
• Chromium       - Navegador de código abierto

🛠️  HERRAMIENTAS DISPONIBLES:
• Terminal       - xfce4-terminal
• Editor         - mousepad
• Explorador     - thunar
• Editor avanzado- vim, nano, gedit

🔐 ACCESO AL ESCRITORIO:
• Web (noVNC):   http://localhost:6901 o 6902
• VNC Cliente:   localhost:5901 o 5902
• Usuario:       headless
• Contraseña:    MiPasswordFuerte123

📁 WORKSPACE:
• Carpeta:       /home/headless/workspace
• Persistente:   Sí (montado desde ./dataA o ./dataB)

💡 CONSEJOS:
• Doble clic en los iconos del escritorio para abrir aplicaciones
• Los archivos en workspace se guardan permanentemente
• Usa Ctrl+Alt+T para abrir terminal rápidamente
• Firefox y Chromium están optimizados para contenedores

🚀 COMANDOS ÚTILES:
• firefox        - Abrir Firefox
• chromium-browser --no-sandbox - Abrir Chromium
• thunar         - Explorador de archivos
• mousepad       - Editor de texto

=====================================
¡Disfruta tu escritorio XFCE! 🎉
EOF

    # Hacer archivo ejecutable y cambiar propietario
    chmod 644 "/home/headless/Desktop/INFO_SISTEMA.txt"
    if [ "$(id -u)" = "0" ]; then
        chown headless:headless "/home/headless/Desktop/INFO_SISTEMA.txt" 2>/dev/null || true
    fi
    
    echo "✅ Archivo de información creado"
}

# Función para mostrar información de bienvenida
show_welcome_info() {
    echo "🎉 ¡Escritorio XFCE configurado exitosamente!"
    echo "📋 Información del contenedor:"
    echo "   • Navegadores instalados: Firefox, Chromium"
    echo "   • Herramientas: Terminal, Editor, Explorador"
    echo "   • Acceso web: http://localhost:6901 o 6902"
    echo "   • Usuario VNC: headless"
    echo "   • Contraseña VNC: MiPasswordFuerte123"
    echo ""
    echo "💡 Los accesos directos están disponibles en el escritorio"
    echo "🔗 Haz doble clic en los iconos para abrir las aplicaciones"
    echo "📄 Revisa el archivo INFO_SISTEMA.txt en el escritorio"
}

# Función principal
main() {
    echo "🐳 Iniciando configuración automática del contenedor XFCE..."
    
    # Esperar a que el sistema esté listo
    sleep 2
    
    # Ejecutar configuraciones
    setup_desktop
    setup_browsers
    setup_desktop_theme
    create_system_info
    show_welcome_info
    
    echo "✅ Configuración automática completada"
}

# Ejecutar si se llama directamente
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    main "$@"
fi