# Certificados SSL para Nextcloud Multi-Desktop Environment

Este proyecto incluye una solución completa para generar certificados SSL autofirmados wildcard para uso en entorno multi-desktop con el dominio `*.nextcloud.net`. Los certificados proporcionan comunicación segura entre todos los servicios y escritorios virtuales.

## 📋 Tabla de Contenidos

- [Requisitos](#requisitos)
- [Estructura de Archivos](#estructura-de-archivos)
- [Generación de Certificados](#generación-de-certificados)
- [Instalación y Configuración](#instalación-y-configuración)
- [Verificación](#verificación)
- [Solución de Problemas](#solución-de-problemas)
- [Seguridad](#seguridad)

## 🔧 Requisitos

- Docker y Docker Compose instalados
- Permisos de escritura en el directorio del proyecto
- OpenSSL instalado en el host (para verificación)

## 📁 Estructura de Archivos

```
PROYECTO_V1/
├── generate-ssl-certs.sh              # Script principal para generar certificados
├── self-signed-certs/                 # Directorio del generador de certificados
│   ├── Dockerfile                     # Imagen Docker para generación
│   └── generate-certs.sh              # Script interno de generación
├── swag-config/
│   └── etc/letsencrypt/live/nextcloud.net/  # Destino de los certificados
│       ├── fullchain.pem              # Certificado completo
│       ├── privkey.pem                # Clave privada
│       └── cert.pem                   # Certificado (copia de fullchain.pem)
├── ssl-certs/
│   └── mariadb/                       # Certificados SSL para MariaDB
│       ├── server-cert.pem           # Certificado del servidor DB
│       ├── server-key.pem            # Clave privada del servidor DB
│       └── my-ssl.cnf                # Configuración SSL de MariaDB
└── proxy-nginx/
    └── nginx.conf                     # Configuración que usa los certificados web
```

## 🚀 Generación de Certificados

### Método 1: Script Automático (Recomendado)

Ejecuta el script principal que automatiza todo el proceso:

```bash
./generate-ssl-certs.sh
```

Este script:
1. ✅ Construye la imagen Docker del generador
2. ✅ Genera certificados wildcard para `*.nextcloud.net`
3. ✅ Crea backup de certificados existentes
4. ✅ Copia los certificados a la ubicación correcta
5. ✅ Establece permisos adecuados
6. ✅ Muestra información del certificado generado

### Método 2: Manual

Si prefieres ejecutar el proceso manualmente:

```bash
# 1. Construir la imagen del generador
docker build -t nextcloud-cert-generator ./self-signed-certs/

# 2. Crear directorio temporal
mkdir -p temp-certs

# 3. Generar certificados
docker run --rm -v "$(pwd)/temp-certs:/output" nextcloud-cert-generator

# 4. Copiar a la ubicación final
mkdir -p swag-config/etc/letsencrypt/live/nextcloud.net
cp temp-certs/*.pem swag-config/etc/letsencrypt/live/nextcloud.net/

# 5. Establecer permisos
chmod 644 swag-config/etc/letsencrypt/live/nextcloud.net/{fullchain,cert}.pem
chmod 600 swag-config/etc/letsencrypt/live/nextcloud.net/privkey.pem

# 6. Limpiar archivos temporales
rm -rf temp-certs
```

## ⚙️ Instalación y Configuración

### 1. Generar los Certificados

```bash
./generate-ssl-certs.sh
```

### 2. Reiniciar el Proxy Nginx

Para que nginx cargue los nuevos certificados:

```bash
# Opción 1: Reiniciar solo nginx-proxy
docker compose restart nginx-proxy

# Opción 2: Reiniciar todo el stack
docker compose down && docker compose up -d
```

### 3. Configurar DNS Local

Asegúrate de que tu sistema resuelva los dominios localmente. Añade a tu `/etc/hosts` (Linux/Mac) o `C:\Windows\System32\drivers\etc\hosts` (Windows):

```
127.0.0.1 nextcloud.net
127.0.0.1 www.nextcloud.net
127.0.0.1 admin.nextcloud.net
127.0.0.1 api.nextcloud.net
```

O usa el servicio CoreDNS incluido en el proyecto.

## 🔍 Verificación

### Verificar la Generación de Certificados

```bash
# Verificar que los archivos existen
ls -la swag-config/etc/letsencrypt/live/nextcloud.net/

# Verificar información del certificado
openssl x509 -in swag-config/etc/letsencrypt/live/nextcloud.net/fullchain.pem -text -noout | grep -A1 "Subject:"

# Verificar dominios incluidos (SAN)
openssl x509 -in swag-config/etc/letsencrypt/live/nextcloud.net/fullchain.pem -text -noout | grep -A10 "Subject Alternative Name"

# Verificar fechas de validez
openssl x509 -in swag-config/etc/letsencrypt/live/nextcloud.net/fullchain.pem -noout -dates
```

### Verificar HTTPS en el Navegador

1. Navega a: `https://nextcloud.net`
2. El navegador mostrará una advertencia de certificado no confiable
3. Acepta la advertencia para continuar
4. Verifica que la conexión sea HTTPS

### Prueba con curl

```bash
# Prueba ignorando verificación SSL (para desarrollo)
curl -k https://nextcloud.net

# Verificar certificado
curl -vvv https://nextcloud.net 2>&1 | grep -A5 -B5 certificate
```

## 🛠️ Solución de Problemas

### Error: "Docker no está ejecutándose"

```bash
# En Ubuntu/Debian
sudo systemctl start docker

# En otros sistemas, asegúrate de que Docker Desktop esté ejecutándose
```

### Error: "Permission denied"

```bash
# Hacer el script ejecutable
chmod +x generate-ssl-certs.sh

# Verificar permisos del directorio
ls -la swag-config/etc/letsencrypt/live/nextcloud.net/
```

### Nginx no carga los certificados

1. Verifica que los archivos existan:
   ```bash
   ls -la swag-config/etc/letsencrypt/live/nextcloud.net/
   ```

2. Verifica la configuración de nginx:
   ```bash
   docker compose exec nginx-proxy nginx -t
   ```

3. Reinicia nginx:
   ```bash
   docker compose restart nginx-proxy
   ```

### El navegador sigue mostrando "No seguro"

Esto es normal con certificados autofirmados. Para eliminar la advertencia:

1. **Chrome/Edge**: Añade el certificado al almacén de confianza del sistema
2. **Firefox**: Añade una excepción de seguridad
3. **Para desarrollo**: Ignora las advertencias SSL

### Regenerar Certificados

Si necesitas regenerar los certificados (por ejemplo, si expiraron):

```bash
# Eliminar certificados existentes
rm -rf swag-config/etc/letsencrypt/live/nextcloud.net/*

# Regenerar
./generate-ssl-certs.sh
```

## 🔐 Seguridad

### ⚠️ Importante

- **Solo para desarrollo local**: Estos certificados son autofirmados y NO deben usarse en producción
- **No compartas las claves privadas**: Los archivos `.pem` contienen información sensible
- **Validez limitada**: Los certificados tienen una validez de 10 años por defecto

### Configuración del Certificado

Los certificados generados incluyen:

- **CN (Common Name)**: `*.nextcloud.net`
- **SAN (Subject Alternative Names)**:
  - `nextcloud.net`
  - `*.nextcloud.net`
  - `www.nextcloud.net`
- **Algoritmo**: RSA 2048 bits
- **Validez**: 10 años (3650 días)
- **Uso**: Autenticación de servidor, cifrado de datos

### Instalar Certificado en el Sistema (Opcional)

Para evitar advertencias del navegador, puedes instalar el certificado en el almacén de confianza:

#### Ubuntu/Debian
```bash
sudo cp swag-config/etc/letsencrypt/live/nextcloud.net/fullchain.pem /usr/local/share/ca-certificates/nextcloud.crt
sudo update-ca-certificates
```

#### CentOS/RHEL/Fedora
```bash
sudo cp swag-config/etc/letsencrypt/live/nextcloud.net/fullchain.pem /etc/pki/ca-trust/source/anchors/nextcloud.crt
sudo update-ca-trust
```

#### macOS
```bash
sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain swag-config/etc/letsencrypt/live/nextcloud.net/fullchain.pem
```

#### Windows
1. Doble clic en `fullchain.pem`
2. Seleccionar "Instalar certificado"
3. Elegir "Máquina local" → "Entidades de certificación raíz de confianza"

## 🌐 Instalación del Certificado en el Sistema (Eliminar Advertencias del Navegador)

Para que los navegadores reconozcan el certificado como confiable y no muestren advertencias de seguridad:

### Método 1: Instalación Automática en el Sistema (Recomendado)

```bash
# Instalar certificado en el almacén del sistema Linux
./install-ssl-cert-system.sh
```

Este script:
- ✅ Detecta automáticamente tu distribución Linux
- ✅ Instala el certificado en el almacén correcto del sistema
- ✅ Actualiza los certificados de confianza
- ✅ Funciona con Ubuntu, Debian, CentOS, Fedora, Arch Linux

### Método 2: Instalación Manual en Navegadores

```bash
# Obtener instrucciones específicas para cada navegador
./install-ssl-cert-browsers.sh
```

Este script proporciona:
- 📋 Instrucciones paso a paso para Chrome, Firefox, Edge
- 🔧 Instalación automática en Firefox (si tienes certutil)
- 📁 Copia el certificado a una ubicación fácil de acceder
- 🖥️ Crea acceso directo en el escritorio

### Desinstalar el Certificado

Si necesitas remover el certificado del sistema:

```bash
./uninstall-ssl-cert-system.sh
```

### Verificar la Instalación

Después de instalar el certificado:

```bash
# Verificar que funciona sin advertencias
curl https://nextcloud.net

# Si no hay errores SSL, ¡el certificado está correctamente instalado!
```

## 📝 Notas Adicionales

- Los certificados se regeneran cada vez que ejecutas el script
- Se crean backups automáticos de certificados existentes
- El script es idempotente (puedes ejecutarlo múltiples veces sin problemas)
- Los logs de generación se muestran en tiempo real
- **Después de instalar el certificado**: Reinicia completamente tus navegadores
- **Para Firefox**: Puede requerir instalación manual adicional

## 🤝 Contribuciones

Si encuentras algún problema o tienes sugerencias de mejora, no dudes en crear un issue o pull request.

---

**Generado por**: Sistema de generación automática de certificados SSL
**Fecha**: $(date +%Y-%m-%d)
**Proyecto**: Nextcloud con Docker Compose