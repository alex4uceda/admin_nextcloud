#!/bin/bash
# Script de información del sistema para mostrar en el escritorio

# Crear archivo de información del sistema
cat > /home/headless/Desktop/INFO_SISTEMA.txt << 'EOF'
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

# Hacer el archivo de solo lectura para preservar la información
chmod 444 /home/headless/Desktop/INFO_SISTEMA.txt

# Cambiar propietario si es root
if [ "$(id -u)" = "0" ]; then
    chown headless:headless /home/headless/Desktop/INFO_SISTEMA.txt 2>/dev/null || true
fi