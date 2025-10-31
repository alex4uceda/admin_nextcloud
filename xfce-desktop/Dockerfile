FROM accetto/ubuntu-vnc-xfce

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive

# Switch to root user for installations
USER root

# Update package list and install browsers and essential tools
RUN apt-get update && apt-get install -y \
    firefox \
    chromium-browser \
    mousepad \
    thunar \
    xfce4-terminal \
    wget \
    curl \
    gedit \
    git \
    vim \
    nano \
    htop \
    unzip \
    zip \
    && apt-get autoremove -y \
    && apt-get autoclean \
    && rm -rf /var/lib/apt/lists/*

# Copy the automated setup script
COPY setup-desktop.sh /usr/local/bin/setup-desktop.sh
RUN chmod +x /usr/local/bin/setup-desktop.sh

# Create startup script that runs our automation
RUN mkdir -p /dockerstartup && \
    echo '#!/bin/bash' > /dockerstartup/setup_desktop.sh && \
    echo 'echo "🚀 Ejecutando configuración automática del escritorio..."' >> /dockerstartup/setup_desktop.sh && \
    echo '/usr/local/bin/setup-desktop.sh' >> /dockerstartup/setup_desktop.sh && \
    echo 'echo "✅ Escritorio configurado automáticamente"' >> /dockerstartup/setup_desktop.sh && \
    chmod +x /dockerstartup/setup_desktop.sh

# Create a custom entrypoint that runs our setup and then the original entrypoint
RUN echo '#!/bin/bash' > /usr/local/bin/custom-entrypoint.sh && \
    echo 'set -e' >> /usr/local/bin/custom-entrypoint.sh && \
    echo '' >> /usr/local/bin/custom-entrypoint.sh && \
    echo '# Run desktop setup in background after VNC starts' >> /usr/local/bin/custom-entrypoint.sh && \
    echo '(' >> /usr/local/bin/custom-entrypoint.sh && \
    echo '  sleep 5  # Wait for VNC to be ready' >> /usr/local/bin/custom-entrypoint.sh && \
    echo '  /dockerstartup/setup_desktop.sh' >> /usr/local/bin/custom-entrypoint.sh && \
    echo ') &' >> /usr/local/bin/custom-entrypoint.sh && \
    echo '' >> /usr/local/bin/custom-entrypoint.sh && \
    echo '# Start the original VNC startup script' >> /usr/local/bin/custom-entrypoint.sh && \
    echo 'exec /dockerstartup/vnc_startup.sh "$@"' >> /usr/local/bin/custom-entrypoint.sh && \
    chmod +x /usr/local/bin/custom-entrypoint.sh

# Set our custom entrypoint
ENTRYPOINT ["/usr/local/bin/custom-entrypoint.sh"]
CMD ["--wait"]

# Add labels for better container management
LABEL maintainer="Custom XFCE Desktop with Auto-Setup" \
      description="Ubuntu XFCE desktop with automated browser and desktop configuration" \
      browsers="Firefox, Chromium" \
      features="Auto-setup, Desktop shortcuts, Theme configuration"