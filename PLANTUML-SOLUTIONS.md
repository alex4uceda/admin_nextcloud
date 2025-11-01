# Documentación de Diagramas Arquitecturales - Nextcloud Multi-Desktop

Este directorio contiene diagramas PlantUML que documentan la arquitectura completa del sistema Nextcloud Multi-Desktop con servicios de backup y segmentación de red.

## 🚨 Error 520 - Servidor PlantUML no disponible

El error que estás experimentando se debe a problemas de conectividad con el servidor online de PlantUML.

## 🔧 Soluciones Disponibles

### 1. 📱 **Usar PlantText.com (Online)**
1. Ve a https://www.planttext.com/
2. Copia y pega el contenido de cualquier archivo `.puml`
3. Click en "Refresh" para generar el diagrama
4. Puedes exportar como PNG, SVG, etc.

### 2. 🔌 **Configurar VS Code con Servidor Local**

#### Paso 1: Instalar la extensión PlantUML
```bash
# Busca e instala la extensión "PlantUML" de jebbs en VS Code
# O usa el comando:
code --install-extension jebbs.plantuml
```

#### Paso 2: Configurar servidor local
1. Abre VS Code Settings (Ctrl+,)
2. Busca "plantuml"
3. Cambia la configuración:
   - `plantuml.server`: `http://localhost:8080/plantuml`
   - `plantuml.render`: `Local`

### 3. 🐳 **Usar PlantUML con Docker (Recomendado)**

#### Ejecutar servidor PlantUML local:
```bash
# Ejecutar servidor PlantUML en Docker
docker run -d -p 8080:8080 plantuml/plantuml-server:jetty

# Luego cambiar la configuración de VS Code:
# plantuml.server: http://localhost:8080/plantuml
```

### 4. 📝 **Método Manual - Ver diagramas como texto**

Los diagramas están diseñados para ser legibles incluso como código:

## 📊 **Diagramas Disponibles**

#### 🏗️ infrastructure-diagram.puml
**Arquitectura Completa del Sistema**
- **Servicios Core**: nginx-proxy, Nextcloud, MariaDB con SSL, Redis
- **DNS Personalizado**: CoreDNS con zonas locales
- **Escritorios Virtuales**: 3 desktops XFCE con noVNC
- **Backup Automatizado**: Servicio de respaldo con sync remoto
- **Administración**: Portainer para gestión Docker
- **Redes Segmentadas**: Red principal + red aislada

#### 🚀 deployment-flow.puml  
**Flujo de Despliegue Automatizado**
- **Secuencia completa** de instalación
- **Scripts de automatización**: start.sh, SSL, DNS
- **Verificaciones** de salud y conectividad
- **Configuración de servicios** paso a paso
- **Integración de backup** desde el inicio

#### 🌐 network-architecture.puml
**Arquitectura de Red Avanzada**
- **Red Principal (172.18.0.0/17)**: 32,766 IPs disponibles
- **Red Aislada (172.18.128.0/24)**: Cliente C controlado
- **Segmentación VLSM**: Optimización de rangos IP
- **DNS Dual**: CoreDNS en ambas redes
- **Proxy Inverso**: SSL termination centralizado
- **Mapeo de puertos**: Servicios web y escritorios

#### 🔄 system-states.puml
**Estados y Transiciones del Sistema**
- **Ciclo de vida completo**: inicio → operación → mantenimiento
- **Estados de backup**: programado, ejecutando, completado
- **Manejo de errores**: recuperación automática
- **Health checks**: monitoreo continuo
- **Comandos de troubleshooting**: diagnóstico y reparación

#### 📊 dns.puml
**Configuración DNS Detallada**
- **Zonas DNS locales**: nextcloud.net, services.dev, example.local
- **Forwarding externo**: 1.1.1.1, 8.8.8.8
- **Resolución interna**: servicios por nombre
- **Configuración Corefile**: sintaxis y opciones

## 🚀 **Inicio Rápido con Docker PlantUML**

### Paso 1: Ejecutar servidor local
```bash
docker run -d -p 8080:8080 --name plantuml-server plantuml/plantuml-server:jetty
```

### Paso 2: Configurar VS Code
1. Instalar extensión PlantUML
2. Configurar servidor: `http://localhost:8080/plantuml`
3. Abrir cualquier archivo `.puml`
4. Presionar `Alt+D` para previsualizar

### Paso 3: Exportar diagramas
```bash
# Generar PNG de todos los diagramas disponibles
curl -X POST --data-urlencode "text@infrastructure-diagram.puml" http://localhost:8080/plantuml/png > infrastructure.png
curl -X POST --data-urlencode "text@deployment-flow.puml" http://localhost:8080/plantuml/png > deployment.png
curl -X POST --data-urlencode "text@network-architecture.puml" http://localhost:8080/plantuml/png > network.png
curl -X POST --data-urlencode "text@system-states.puml" http://localhost:8080/plantuml/png > states.png
curl -X POST --data-urlencode "text@dns.puml" http://localhost:8080/plantuml/png > dns.png

# Script para exportar todos los diagramas automáticamente
#!/bin/bash
echo "Exportando diagramas PlantUML..."
for file in *.puml; do
    name=$(basename "$file" .puml)
    echo "Generando ${name}.png..."
    curl -X POST --data-urlencode "text@${file}" http://localhost:8080/plantuml/png > "${name}.png"
done
echo "Exportación completada!"
```

### Paso 4: Generar documentación completa
```bash
# Crear directorio para diagramas exportados
mkdir -p docs/diagrams

# Exportar todos los diagramas con metadatos
for diagram in infrastructure deployment-flow network-architecture system-states dns; do
    echo "Procesando ${diagram}..."
    
    # PNG para documentación
    curl -X POST --data-urlencode "text@${diagram}.puml" \
         http://localhost:8080/plantuml/png > docs/diagrams/${diagram}.png
    
    # SVG para web (escalable)
    curl -X POST --data-urlencode "text@${diagram}.puml" \
         http://localhost:8080/plantuml/svg > docs/diagrams/${diagram}.svg
    
    # TXT para revisión de código
    curl -X POST --data-urlencode "text@${diagram}.puml" \
         http://localhost:8080/plantuml/txt > docs/diagrams/${diagram}.txt
done
```

## 🌐 **Herramientas Online Alternativas**

1. **PlantText**: https://www.planttext.com/
2. **PlantUML Online Server**: http://www.plantuml.com/plantuml/uml/
3. **Gravizo**: http://www.gravizo.com/
4. **CodeUML**: https://codeuml.com/

## 📱 **Apps Móviles/Desktop**

- **PlantUML QEditor** (Desktop)
- **PlantUML Viewer** (Aplicaciones web)
- **Extensiones de navegador** para GitHub/GitLab

## ⚡ **Solución Inmediata**

1. Ve a https://www.planttext.com/
2. Copia el contenido de `infrastructure-diagram.puml`
3. Pégalo en el editor
4. Click "Refresh"
5. ¡Listo! Puedes ver y exportar el diagrama

Los diagramas están completamente funcionales y documentan toda tu infraestructura de Nextcloud de manera profesional.