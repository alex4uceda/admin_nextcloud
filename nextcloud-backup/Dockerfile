# ===================================================================================
# NEXTCLOUD BACKUP CONTAINER
# ===================================================================================
# 
# OBJETIVO:
# - Backup automático de base de datos MySQL/MariaDB
# - Sincronización de carpetas Nextcloud via RSYNC over SSH
# - Conexión encriptada a servidor remoto de backups
# - Programación automática via cron jobs
#
# HERRAMIENTAS INCLUIDAS:
# - rsync: Sincronización incremental de archivos
# - mysql-client: Para conexión y dump de base de datos
# - openssh-client: Para conexiones SSH encriptadas
# - cron: Para programación de tareas automáticas
# - curl: Para monitoreo y health checks
# ===================================================================================

FROM alpine:latest

# Metadata del contenedor
LABEL maintainer="Nextcloud Backup Service"
LABEL description="Automated backup service for Nextcloud infrastructure"
LABEL version="1.0.0"

# Instalar dependencias del sistema
RUN apk update && apk add --no-cache \
    # Herramientas de backup y sincronización
    rsync \
    mysql-client \
    mariadb-client \
    # Conectividad SSH encriptada
    openssh-client \
    openssh-keygen \
    # Programación de tareas
    dcron \
    # Herramientas del sistema
    bash \
    curl \
    gzip \
    tar \
    # Utilidades de fecha y logs
    coreutils \
    findutils \
    # Editor de texto para configuración
    nano \
    # Herramientas de red para diagnóstico
    netcat-openbsd \
    iputils \
    && rm -rf /var/cache/apk/*

# Crear usuario para backups con permisos especiales para cron
RUN addgroup -g 1000 backup && \
    adduser -D -s /bin/bash -u 1000 -G backup backup && \
    echo "backup:backup" | chpasswd

# Crear directorios necesarios
RUN mkdir -p /app/scripts \
    /app/config \
    /app/logs \
    /home/backup/.ssh \
    /backups/local \
    /data/mysql \
    /data/nextcloud \
    /data/nextcloud_data \
    /data/redis

# Establecer permisos correctos incluyendo cron
RUN chown -R backup:backup /app /home/backup /backups /data && \
    chmod 700 /home/backup/.ssh && \
    mkdir -p /var/spool/cron/crontabs && \
    chown -R backup:backup /var/spool/cron/crontabs && \
    chmod 755 /var/spool/cron/crontabs

# Copiar scripts de backup
COPY scripts/ /app/scripts/
COPY config/ /app/config/

# Hacer scripts ejecutables
RUN chmod +x /app/scripts/*.sh && \
    chown -R backup:backup /app/scripts

# Configuración de SSH para el usuario backup
RUN echo "Host *" > /home/backup/.ssh/config && \
    echo "    StrictHostKeyChecking no" >> /home/backup/.ssh/config && \
    echo "    UserKnownHostsFile /dev/null" >> /home/backup/.ssh/config && \
    echo "    LogLevel ERROR" >> /home/backup/.ssh/config && \
    chmod 600 /home/backup/.ssh/config && \
    chown backup:backup /home/backup/.ssh/config

# Crear archivo de crontab personalizable
RUN echo "# Nextcloud Backup Cron Jobs" > /var/spool/cron/crontabs/backup && \
    echo "# Formato: minuto hora día mes día_semana comando" >> /var/spool/cron/crontabs/backup && \
    echo "# Backup completo diario a las 2:00 AM" >> /var/spool/cron/crontabs/backup && \
    echo "0 2 * * * /app/scripts/backup-full.sh >> /app/logs/backup.log 2>&1" >> /var/spool/cron/crontabs/backup && \
    echo "# Backup incremental cada 6 horas" >> /var/spool/cron/crontabs/backup && \
    echo "0 */6 * * * /app/scripts/backup-incremental.sh >> /app/logs/backup.log 2>&1" >> /var/spool/cron/crontabs/backup && \
    echo "# Limpieza de logs semanalmente" >> /var/spool/cron/crontabs/backup && \
    echo "0 3 * * 0 /app/scripts/cleanup-logs.sh >> /app/logs/backup.log 2>&1" >> /var/spool/cron/crontabs/backup && \
    chmod 600 /var/spool/cron/crontabs/backup && \
    chown backup:backup /var/spool/cron/crontabs/backup

# Variables de entorno por defecto
ENV BACKUP_DB_HOST=db \
    BACKUP_DB_PORT=3306 \
    BACKUP_DB_NAME=nextcloud \
    BACKUP_RETENTION_DAYS=30 \
    BACKUP_LOG_LEVEL=INFO \
    BACKUP_COMPRESSION=true \
    BACKUP_VERIFY_CHECKSUMS=true \
    TZ=America/El_Salvador

# Script de punto de entrada
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh && \
    chown backup:backup /app/entrypoint.sh

# Mantenerse como root para poder usar cron, pero cambiar a backup para scripts
# USER backup

# Establecer directorio de trabajo
WORKDIR /app

# Exponer puerto para health check (opcional)
EXPOSE 8080

# Health check para monitorear el servicio
HEALTHCHECK --interval=30m --timeout=10s --start-period=5s --retries=3 \
    CMD /app/scripts/health-check.sh || exit 1

# Punto de entrada
ENTRYPOINT ["/app/entrypoint.sh"]

# Comando por defecto: iniciar cron en primer plano
CMD ["crond", "-f", "-l", "2"]