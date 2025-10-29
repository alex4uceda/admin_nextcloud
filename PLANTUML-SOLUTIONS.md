# Soluciones para Visualizar Diagramas PlantUML

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

#### infrastructure-diagram.puml
- Muestra la arquitectura completa
- Contenedores: CoreDNS, nginx-proxy, Nextcloud, MariaDB, Redis
- Conexiones y flujos de datos
- Volúmenes y montajes

#### deployment-flow.puml  
- Secuencia de instalación paso a paso
- Interacciones entre scripts y servicios
- Proceso completo de despliegue

#### network-architecture.puml
- Topología de red detallada
- Configuración de seguridad
- Mapeo de puertos y volúmenes

#### system-states.puml
- Estados del sistema durante el ciclo de vida
- Transiciones y manejo de errores
- Comandos de troubleshooting

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
# Generar PNG de todos los diagramas
curl -X POST --data-urlencode "text@infrastructure-diagram.puml" http://localhost:8080/plantuml/png > infrastructure.png
curl -X POST --data-urlencode "text@deployment-flow.puml" http://localhost:8080/plantuml/png > deployment.png
curl -X POST --data-urlencode "text@network-architecture.puml" http://localhost:8080/plantuml/png > network.png
curl -X POST --data-urlencode "text@system-states.puml" http://localhost:8080/plantuml/png > states.png
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